import spidev
import time
import gpiod
import threading
from bluezero import peripheral


class EEGRecorderBLE:
    def __init__(self, interval_ms=4):
        # 初始化 SPI
        self.interval = interval_ms / 1000
        self.spi = spidev.SpiDev()
        self.spi_2 = spidev.SpiDev()
        self.spi.open(0, 0)
        self.spi_2.open(0, 1)
        self.spi.max_speed_hz = 4000000
        self.spi_2.max_speed_hz = 4000000
        self.spi.mode = 0b01
        self.spi_2.mode = 0b01
        self.spi.bits_per_word = 8
        self.spi_2.bits_per_word = 8

        # 初始化 CS 引脚
        chip = gpiod.chip("0")
        self.cs_line = chip.get_line(19)
        cs_line_out = gpiod.line_request()
        cs_line_out.consumer = "SPI_CS"
        cs_line_out.request_type = gpiod.line_request.DIRECTION_OUTPUT
        self.cs_line.request(cs_line_out)
        self.cs_line.set_value(1)

        # 初始化按钮（可选）
        button_pin_1 = 26
        line_1 = chip.get_line(button_pin_1)
        button_req = gpiod.line_request()
        button_req.consumer = "Button"
        button_req.request_type = gpiod.line_request.DIRECTION_INPUT
        line_1.request(button_req)
        self.line_1 = line_1

        # ADS1299 控制指令
        self.data_test = 0x7FFFFF
        self.data_check = 0xFFFFFF
        self.result = [0] * 27
        self.result_2 = [0] * 27

        self.data_all = [[] for _ in range(16)]

        # 配置 ADS1299 两个通道
        self._init_ads1299(self.spi, self._write_byte, self._send_command)
        self._init_ads1299(self.spi_2, self._write_byte_2, self._send_command_2)

        # ==== BLE ====
        self.device_name = "EEGPi"
        self.service_uuid = "12345678-1234-5678-1234-56789abcdef0"
        self.char_uuid = "12345678-1234-5678-1234-56789abcdef1"
        self._setup_ble()

    def _send_command(self, command):
        self.spi.xfer([command])

    def _send_command_2(self, command):
        self.cs_line.set_value(0)
        self.spi_2.xfer([command])
        self.cs_line.set_value(1)

    def _write_byte(self, reg, data):
        self.spi.xfer([0x40 | reg, 0x00, data])

    def _write_byte_2(self, reg, data):
        self.cs_line.set_value(0)
        self.spi_2.xfer([0x40 | reg, 0x00, data])
        self.cs_line.set_value(1)

    def _init_ads1299(self, spi, write_func, send_func):
        send_func(0x02)  # WAKEUP
        send_func(0x0A)  # STOP
        send_func(0x06)  # RESET
        time.sleep(0.1)
        send_func(0x11)  # SDATAC

        write_func(0x14, 0x80)  # GPIO 设置
        write_func(0x01, 0x96)
        write_func(0x02, 0xD4)
        write_func(0x03, 0xFF)
        write_func(0x04, 0x00)
        write_func(0x0D, 0x00)
        write_func(0x0E, 0x00)
        write_func(0x0F, 0x00)
        write_func(0x10, 0x00)
        write_func(0x11, 0x00)
        write_func(0x15, 0x20)
        write_func(0x17, 0x00)

        for ch in range(0x05, 0x0D):
            write_func(ch, 0x00)

        send_func(0x10)  # RDATAC
        send_func(0x08)  #

    def _setup_ble(self):
        self.ble = peripheral.Peripheral(
            adapter_address="2C:CF:67:97:03:4B",
            local_name=self.device_name
        )
        self.ble.add_service(srv_id=1, uuid=self.service_uuid, primary=True)
        self.ble.add_characteristic(
            srv_id=1,
            chr_id=1,
            uuid=self.char_uuid,
            value=[0] * 48,
            notifying=True,
            flags=['read', 'notify'],
            read_callback=self.read_callback
        )

        self.ble.on_connect = self.on_connect

    def read_callback(self):
        return self.result

    def read_16ch_data(self):
        output = self.spi.readbytes(27)
        self.cs_line.set_value(0)
        output_2 = self.spi_2.readbytes(27)
        self.cs_line.set_value(1)

        eeg_data = [0] * 16
        if output[0] == 192 and output[1] == 0 and output[2] == 8:
            for a in range(3, 25, 3):
                voltage_1 = (output[a] << 8) | output[a + 1]
                voltage_1 = (voltage_1 << 8) | output[a + 2]
                convert_voltage = voltage_1 | self.data_test
                if convert_voltage == self.data_check:
                    voltage_1_after = voltage_1 - 16777214
                else:
                    voltage_1_after = voltage_1
                ch = int(a / 3)
                self.result[ch] = round(1000000 * 4.5 * (voltage_1_after / 16777215), 2)

            for a in range(3, 25, 3):
                voltage_2 = (output_2[a] << 8) | output_2[a + 1]
                voltage_2 = (voltage_2 << 8) | output_2[a + 2]
                convert_voltage = voltage_2 | self.data_test
                if convert_voltage == self.data_check:
                    voltage_2_after = voltage_2 - 16777214
                else:
                    voltage_2_after = voltage_2
                ch = int(a / 3)
                self.result_2[ch] = round(1000000 * 4.5 * (voltage_2_after / 16777215), 2)

            eeg_data = [
                self.result[1], self.result[2], self.result[3], self.result[4],
                self.result[5], self.result[6], self.result[7], self.result[8],
                self.result_2[1], self.result_2[2], self.result_2[3], self.result_2[4],
                self.result_2[5], self.result_2[6], self.result_2[7], self.result_2[8]
            ]
        # print(eeg_data)
        return eeg_data

    def to_bytes(self, value):
        if value < 0:
            value = (1 << 24) + value
        return int(value).to_bytes(3, 'big', signed=False)

    def start(self):
        print(f"🚀 Advertising as '{self.device_name}'")
        threading.Thread(target=self.ble.publish, daemon=True).start()
        print("🔍 等待连接...")
        while not self.ble.characteristics:
            time.sleep(0.1)
        self.characteristic = self.ble.characteristics[0]
        print("✅ BLE 服务准备就绪，开始推送")
        self._schedule()

    def _schedule(self):
        eeg = self.read_16ch_data()
        try:
            data_bytes = b''.join(self.to_bytes(int(x)) for x in eeg)
            self.characteristic.set_value(data_bytes)
            self.characteristic.StartNotify()
        except Exception as e:
            print("❌ Notify error:", e)
        self.timer = threading.Timer(self.interval, self._schedule)
        self.timer.start()

    def stop(self):
        if self.timer:
            self.timer.cancel()
        self.spi.close()
        self.spi_2.close()
        print("🛑 BLE 推送已停止")

    def on_connect(self):
        print("📲 设备已连接，自动停止广播")
        self.stop()
        # raise KeyboardInterrupt  # 模拟 Ctrl+C，终止主循环


if __name__ == "__main__":
    try:
        ble = EEGRecorderBLE()
        ble.start()
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        ble.stop()