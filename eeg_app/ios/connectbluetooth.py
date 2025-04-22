import spidev
import time
import gpiod
import threading
from bluezero import peripheral
import json


class EEGRecorderBLE:
    def __init__(self, interval_ms=200):
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

        # ADS1299 控制指令
        self.COMMANDS = {
            'wakeup': 0x02,
            'stop': 0x0A,
            'start': 0x08,
            'reset': 0x06,
            'sdatac': 0x11,
            'rdatac': 0x10,
            'rdata': 0x12
        }

        # 配置 ADS1299 两个通道
        self._initialize_spi_devices()

        # ==== BLE ====
        self.device_name = "EEGPi"
        self.service_uuid = "12345678-1234-5678-1234-56789abcdef0"
        self.char_uuid = "12345678-1234-5678-1234-56789abcdef1"
        self._setup_ble()

    def _send_command(self, spi_dev, command):
        spi_dev.xfer([command])

    def _write_register(self, spi_dev, register, data):
        write = 0x40
        register_write = write | register
        spi_dev.xfer([register_write, 0x00, data])

    def _initialize_spi_devices(self):
        for dev in [self.spi, self.spi_2]:
            self._send_command(dev, self.COMMANDS['wakeup'])
            self._send_command(dev, self.COMMANDS['stop'])
            self._send_command(dev, self.COMMANDS['reset'])
            self._send_command(dev, self.COMMANDS['sdatac'])

            self._write_register(dev, 0x14, 0x80)  # GPIO
            self._write_register(dev, 0x01, 0x96)  # config1
            self._write_register(dev, 0x02, 0xD4)  # config2
            self._write_register(dev, 0x03, 0xFF)  # config3

            for reg in [0x04, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x15, 0x17]:
                self._write_register(dev, reg, 0x00)
            for ch in range(5, 13):
                self._write_register(dev, ch, 0x00)

            self._send_command(dev, self.COMMANDS['rdatac'])
            self._send_command(dev, self.COMMANDS['start'])

    def _read_eeg_data(self, spi_dev):
        output = spi_dev.readbytes(27)
        result = [0] * 8
        for a in range(3, 25, 3):
            voltage = (output[a] << 16) | (output[a + 1] << 8) | output[a + 2]
            data_test = 0x7FFFFF
            data_check = 0xFFFFFF

            convert_voltage = voltage | data_test
            if convert_voltage == data_check:
                voltage_after_convert = (voltage - 16777214)
            else:
                voltage_after_convert = voltage

            channel_num = int((a - 3) / 3)
            if 0 <= channel_num < 8:
                result[channel_num] = round(1000000 * 4.5 * (voltage_after_convert / 16777215), 2)

        return result

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
            flags=['read', 'notify']
        )
        self.ble.on_connect = self.on_connect
        self.ble.on_disconnect = self.on_disconnect

    def read_16ch_data(self):
        # 读取两个 SPI 设备的数据
        data_1 = self._read_eeg_data(self.spi)
        self.cs_line.set_value(0)
        data_2 = self._read_eeg_data(self.spi_2)
        self.cs_line.set_value(1)

        # 合并两个设备的数据
        eeg_data = data_1 + data_2
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
        try:
            eeg = self.read_16ch_data()
            # 将EEG数据转换为JSON格式
            data = {
                "eeg_data": eeg,
                "timestamp": time.time()
            }
            json_data = json.dumps(data)
            data_bytes = json_data.encode('utf-8')
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
        self._send_connection_status(True)
        self.stop()
        raise KeyboardInterrupt

    def on_disconnect(self):
        print("📡 设备已断开连接")
        self._send_connection_status(False)

    def _send_connection_status(self, connected):
        status = {
            "type": "connection_status",
            "connected": connected,
            "device_name": self.device_name
        }
        print(json.dumps(status))


if __name__ == "__main__":
    try:
        ble = EEGRecorderBLE()
        ble.start()
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        ble.stop()