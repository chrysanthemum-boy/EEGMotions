import spidev
import time
from RPi import GPIO
import gpiod
import numpy as np
import torch
import torch.nn.functional as F
import torch.nn as nn
from collections import deque

# GPIO设置
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BOARD)

# 设备配置
button_pin_1 = 26
button_pin_2 = 13

chip = gpiod.chip("0")
cs_line = chip.get_line(19)
cs_line_out = gpiod.line_request()
cs_line_out.consumer = "SPI_CS"
cs_line_out.request_type = gpiod.line_request.DIRECTION_OUTPUT
cs_line.request(cs_line_out)
cs_line.set_value(1)

line_1 = chip.get_line(button_pin_1)
line_2 = chip.get_line(button_pin_2)

button_line_1 = gpiod.line_request()
button_line_1.consumer = "Button"
button_line_1.request_type = gpiod.line_request.DIRECTION_INPUT
line_1.request(button_line_1)

button_line_2 = gpiod.line_request()
button_line_2.consumer = "Button"
button_line_2.request_type = gpiod.line_request.DIRECTION_INPUT
line_2.request(button_line_2)

# SPI初始化
spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 4000000
spi.lsbfirst = False
spi.mode = 0b01
spi.bits_per_word = 8

spi_2 = spidev.SpiDev()
spi_2.open(0, 1)
spi_2.max_speed_hz = 4000000
spi_2.lsbfirst = False
spi_2.mode = 0b01
spi_2.bits_per_word = 8

# SPI命令集
COMMANDS = {
    'wakeup': 0x02,
    'stop': 0x0A,
    'start': 0x08,
    'reset': 0x06,
    'sdatac': 0x11,
    'rdatac': 0x10,
    'rdata': 0x12
}


# 加载对应的模型类
class StressCNN(nn.Module):
    def __init__(self):
        super(StressCNN, self).__init__()

        # 输入通道 1，输出通道 64，卷积核 3
        self.conv1 = nn.Conv1d(in_channels=1, out_channels=64, kernel_size=3)
        self.bn1 = nn.BatchNorm1d(64)
        self.pool1 = nn.MaxPool1d(kernel_size=2)
        self.drop1 = nn.Dropout(0.3)

        self.conv2 = nn.Conv1d(in_channels=64, out_channels=128, kernel_size=3)
        self.bn2 = nn.BatchNorm1d(128)
        self.pool2 = nn.MaxPool1d(kernel_size=2)
        self.drop2 = nn.Dropout(0.3)

        self.fc1 = nn.Linear(128 * 2, 128)
        self.drop3 = nn.Dropout(0.5)
        self.fc2 = nn.Linear(128, 64)
        self.drop4 = nn.Dropout(0.5)
        self.fc3 = nn.Linear(64, 2)  # 最终输出2类

    def forward(self, x):
        # x shape: (batch_size, 1, 16)
        x = self.conv1(x)  # -> (batch_size, 64, 14)
        x = nn.functional.relu(x)
        x = self.bn1(x)
        x = self.pool1(x)  # -> (batch_size, 64, 7)
        x = self.drop1(x)

        x = self.conv2(x)  # -> (batch_size, 128, 5)
        x = nn.functional.relu(x)
        x = self.bn2(x)
        x = self.pool2(x)  # -> (batch_size, 128, 2)
        x = self.drop2(x)

        # 展平
        x = x.view(x.size(0), -1)  # -> (batch_size, 128*2)=256
        x = self.fc1(x)  # -> (batch_size, 128)
        x = nn.functional.relu(x)
        x = self.drop3(x)

        x = self.fc2(x)  # -> (batch_size, 64)
        x = nn.functional.relu(x)
        x = self.drop4(x)

        x = self.fc3(x)  # -> (batch_size, 2)
        return x


class StressCNNBiLSTM(nn.Module):
    def __init__(self):
        super(StressCNNBiLSTM, self).__init__()

        # CNN layers
        self.conv1 = nn.Conv1d(in_channels=1, out_channels=64, kernel_size=3)
        self.bn1 = nn.BatchNorm1d(64)  # 添加了BatchNorm
        self.pool1 = nn.MaxPool1d(kernel_size=2)
        self.drop1 = nn.Dropout(0.3)

        self.conv2 = nn.Conv1d(in_channels=64, out_channels=128, kernel_size=3)
        self.bn2 = nn.BatchNorm1d(128)  # 添加了BatchNorm
        self.pool2 = nn.MaxPool1d(kernel_size=2)
        self.drop2 = nn.Dropout(0.3)

        # BiLSTM layers
        # 卷积池化后的特征大小: (batch_size, 128, 2)
        # 转置后输入LSTM的形状: (batch_size, 2, 128)
        self.lstm1 = nn.LSTM(128, 64, bidirectional=True, batch_first=True)
        self.drop3 = nn.Dropout(0.5)

        # Fully connected layers
        self.fc1 = nn.Linear(64 * 2, 64)  # Flattened LSTM output
        self.fc2 = nn.Linear(64, 32)
        self.fc3 = nn.Linear(32, 2)

    def forward(self, x):
        # CNN forward pass
        x = self.conv1(x)  # (batch_size, 64, 14)
        x = nn.functional.relu(x)
        x = self.bn1(x)  # 添加BatchNorm
        x = self.pool1(x)  # (batch_size, 64, 7)
        x = self.drop1(x)

        x = self.conv2(x)  # (batch_size, 128, 5)
        x = nn.functional.relu(x)
        x = self.bn2(x)  # 添加BatchNorm
        x = self.pool2(x)  # (batch_size, 128, 2)
        x = self.drop2(x)

        # Reshape to (batch_size, sequence_length, feature_size)
        x = x.permute(0, 2, 1)  # (batch_size, 2, 128)

        # BiLSTM forward pass
        x, _ = self.lstm1(x)  # (batch_size, 2, 128)
        x = self.drop3(x)

        # 使用最后一个时间步的输出
        x = x[:, -1, :]  # (batch_size, 64)
        x = self.fc1(x)  # (batch_size, 64)
        x = nn.functional.relu(x)
        x = self.fc2(x)  # (batch_size, 32)
        x = nn.functional.relu(x)
        x = self.fc3(x)  # (batch_size, 2)

        return x


# 使用此类如果你使用的是Transformer模型
class StressTransformer(nn.Module):
    def __init__(self, input_dim=1, embed_dim=64, num_heads=4, ff_dim=128,
                 num_transformer_blocks=2, mlp_units=[64], dropout=0.3, mlp_dropout=0.3):
        super(StressTransformer, self).__init__()

        # 初始特征嵌入层
        self.embedding = nn.Linear(input_dim, embed_dim)

        # Transformer块
        self.transformer_blocks = nn.ModuleList([
            TransformerBlock(embed_dim, num_heads, ff_dim, dropout)
            for _ in range(num_transformer_blocks)
        ])

        # MLP分类器
        layers = []
        for dim in mlp_units:
            layers.append(nn.Linear(embed_dim, dim))
            layers.append(nn.ReLU())
            layers.append(nn.Dropout(mlp_dropout))

        self.mlp = nn.Sequential(*layers)

        # 输出层
        self.output_layer = nn.Linear(mlp_units[-1] if mlp_units else embed_dim, 2)

    def forward(self, x):
        # x的输入形状是(batch_size, seq_len, input_dim)

        # 映射到嵌入空间
        x = self.embedding(x)  # (batch_size, seq_len, embed_dim)

        # 应用Transformer块
        for transformer_block in self.transformer_blocks:
            x = transformer_block(x)

        # 全局平均池化 - 对序列维度进行平均
        x = x.mean(dim=1)  # (batch_size, embed_dim)

        # MLP分类器
        x = self.mlp(x)

        # 输出层
        x = self.output_layer(x)

        return x


class TransformerBlock(nn.Module):
    def __init__(self, embed_dim, num_heads, ff_dim, dropout=0.1):
        super(TransformerBlock, self).__init__()

        # 多头自注意力机制
        self.att = nn.MultiheadAttention(embed_dim=embed_dim, num_heads=num_heads, dropout=dropout, batch_first=True)

        # 前馈神经网络
        self.ffn = nn.Sequential(
            nn.Linear(embed_dim, ff_dim),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(ff_dim, embed_dim)
        )

        # Layer Normalization
        self.layernorm1 = nn.LayerNorm(embed_dim)
        self.layernorm2 = nn.LayerNorm(embed_dim)

        # Dropout
        self.dropout1 = nn.Dropout(dropout)
        self.dropout2 = nn.Dropout(dropout)

    def forward(self, x):
        # 第一个子层：多头自注意力 + 残差连接
        attn_output, _ = self.att(x, x, x)
        x = x + self.dropout1(attn_output)
        x = self.layernorm1(x)

        # 第二个子层：前馈神经网络 + 残差连接
        ffn_output = self.ffn(x)
        x = x + self.dropout2(ffn_output)
        x = self.layernorm2(x)

        return x


def send_command(spi_dev, command):
    spi_dev.xfer([command])


def write_register(spi_dev, register, data):
    write = 0x40
    register_write = write | register
    spi_dev.xfer([register_write, 0x00, data])


def read_eeg_data(spi_dev):
    output = spi_dev.readbytes(27)
    result = [0] * 8
    for a in range(3, 25, 3):
        voltage_1 = (output[a] << 8) | output[a + 1]
        voltage_1 = (voltage_1 << 8) | output[a + 2]

        data_test = 0x7FFFFF
        data_check = 0xFFFFFF

        convert_voltage = voltage_1 | data_test
        if convert_voltage == data_check:
            voltage_1_after_convert = (voltage_1 - 16777214)
        else:
            voltage_1_after_convert = voltage_1

        channel_num = int((a - 3) / 3)
        if 0 <= channel_num < 8:
            result[channel_num] = round(1000000 * 4.5 * (voltage_1_after_convert / 16777215), 2)

    return result


def initialize_spi_devices():
    for dev in [spi, spi_2]:
        send_command(dev, COMMANDS['wakeup'])
        send_command(dev, COMMANDS['stop'])
        send_command(dev, COMMANDS['reset'])
        send_command(dev, COMMANDS['sdatac'])

        write_register(dev, 0x14, 0x80)  # GPIO
        write_register(dev, 0x01, 0x96)  # config1
        write_register(dev, 0x02, 0xD4)  # config2
        write_register(dev, 0x03, 0xFF)  # config3

        for reg in [0x04, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x15, 0x17]:
            write_register(dev, reg, 0x00)
        for ch in range(5, 13):
            write_register(dev, ch, 0x00)

        send_command(dev, COMMANDS['rdatac'])
        send_command(dev, COMMANDS['start'])


def real_time_prediction(model_path, model_type="CNN", window_size=10, threshold=0.5):
    """
    实时预测函数，使用滑动窗口平均化预测结果

    Args:
        model_path: 模型文件路径
        model_type: 模型类型，"CNN"或"Transformer"
        window_size: 滑动窗口大小，用于平均预测结果
        threshold: 预测阈值，超过此阈值则判断为stress
    """
    print(f"加载 {model_type} 模型...")

    # 根据模型类型加载对应的模型
    if model_type == "CNN":
        model = StressCNN()
        # 加载模型参数
        model.load_state_dict(torch.load(model_path, map_location=torch.device('cpu')))
    elif model_type == "Transformer":
        # 对于Transformer模型，需要确保输入格式是(batch_size, seq_len, feature_dim)
        model = StressTransformer()
        model.load_state_dict(torch.load(model_path, map_location=torch.device('cpu')))
    elif model_type == "cnnbilstm":
        model = StressCNNBiLSTM()
        model.load_state_dict(torch.load(model_path, map_location=torch.device('cpu')))
    else:
        raise ValueError(f"不支持的模型类型: {model_type}")

    model.eval()

    print("初始化 EEG 数据缓冲区和 SPI...")
    # 创建一个缓冲区来存储最新的数据点
    data_buffer = []

    # 创建一个队列来存储最近的预测结果
    prediction_window = deque(maxlen=window_size)

    # 创建平滑概率队列
    probability_window = deque(maxlen=window_size)

    initialize_spi_devices()

    print(f"开始实时预测 (使用 {window_size} 帧滑动窗口)...")
    last_prediction = None
    consecutive_same = 0

    try:
        while True:
            # 读取数据
            data_1 = read_eeg_data(spi)
            data_2 = read_eeg_data(spi_2)
            current_data = data_1 + data_2

            if len(current_data) != 16:
                print(f"警告：EEG数据长度异常 ({len(current_data)})")
                time.sleep(0.1)
                continue

            # 存储当前数据点
            data_buffer = current_data

            # 准备输入模型的数据
            if model_type == "CNN":
                # CNN模型: [batch_size=1, channels=1, features=16]
                input_tensor = torch.FloatTensor(data_buffer).unsqueeze(0).unsqueeze(0)
            elif model_type == "Transformer":
                # Transformer模型: [batch_size=1, seq_len=16, feature_dim=1]
                input_tensor = torch.FloatTensor(data_buffer).view(1, 16, 1)
            elif model_type == "cnnbilstm":
                input_tensor = torch.FloatTensor(data_buffer).unsqueeze(0).unsqueeze(0)

            # 预测
            with torch.no_grad():
                outputs = model(input_tensor)
                probabilities = torch.softmax(outputs, dim=1)
                stress_prob = probabilities[0][1].item()  # stress的概率

                # 添加到概率窗口
                probability_window.append(stress_prob)

                # 计算概率的平均值
                avg_probability = sum(probability_window) / len(probability_window)

                # 根据平均概率判断类别
                predicted_class = 1 if avg_probability > threshold else 0
                prediction_window.append(predicted_class)

                # 计算窗口内的多数类别
                stress_count = sum(prediction_window)
                unstress_count = len(prediction_window) - stress_count

                # 综合判断最终预测结果
                final_prediction = 1 if stress_count > unstress_count else 0
                final_confidence = stress_count / len(
                    prediction_window) if final_prediction == 1 else unstress_count / len(prediction_window)

                # 跟踪连续相同的预测次数
                if last_prediction is not None and final_prediction == last_prediction:
                    consecutive_same += 1
                else:
                    consecutive_same = 0
                last_prediction = final_prediction

                # 显示详细信息
                print(f"\n当前stress概率: {stress_prob:.4f}, 窗口平均: {avg_probability:.4f}")
                print(
                    f"窗口中stress占比: {stress_count}/{len(prediction_window)} = {stress_count / len(prediction_window):.2f}")

                # 稳定性指标 - 只有当连续5次以上相同预测才显示最终结果
                if consecutive_same >= 5 or len(prediction_window) < window_size // 2:
                    verdict = "🔴 Stress" if final_prediction == 1 else "🟢 Unstress"
                    print(f"预测结果: {verdict} (置信度: {final_confidence:.2f}, 连续{consecutive_same + 1}次)")
                else:
                    print("稳定中...")

            time.sleep(0.2)  # 控制采样频率

    except KeyboardInterrupt:
        print("\n实时预测已中止")
    except Exception as e:
        print(f"\n发生错误：{e}")
    finally:
        return


def main():
    # 使用你保存的模型路径
    model_path = 'cnn_bilstm_model_50epoch.pth'  # 或 'stress_cnn_model_15epoch.pth'
    model_type = "cnnbilstm"  # 或 "CNN"

    # 滑动窗口大小 (实时预测时累积多少帧进行平均)
    window_size = 15

    # 预测阈值
    threshold = 0.5

    try:
        real_time_prediction(
            model_path=model_path,
            model_type=model_type,
            window_size=window_size,
            threshold=threshold
        )
    except KeyboardInterrupt:
        print("实时预测已中止")
    finally:
        spi.close()
        spi_2.close()


if __name__ == "__main__":
    main()
