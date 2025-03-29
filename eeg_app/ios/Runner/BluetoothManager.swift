import CoreBluetooth
import Flutter

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var eegCharacteristic: CBCharacteristic?

    private var devicesEventSink: FlutterEventSink?
    private var eegEventSink: FlutterEventSink?

    private var discoveredPeripherals: [CBPeripheral] = []
    private let serviceUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef0")
    private let characteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef1")

    init(messenger: FlutterBinaryMessenger) {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        let deviceStream = FlutterEventChannel(name: "bluetooth_device_stream", binaryMessenger: messenger)
        deviceStream.setStreamHandler(DeviceStreamHandler { sink in
            self.devicesEventSink = sink
        })

        let eegStream = FlutterEventChannel(name: "eeg_data_stream", binaryMessenger: messenger)
        eegStream.setStreamHandler(EEGStreamHandler { sink in
            self.eegEventSink = sink
        })
    }

    // MARK: - Flutter 调用接口
    func startScan() {
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("🔍 开始扫描设备")
    }

    func stopScan() {
        centralManager.stopScan()
        print("🛑 停止扫描")
    }

    func connectToPeripheral(id: String) {
        guard let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == id }) else {
            print("❌ 未找到设备")
            return
        }
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("✅ 蓝牙已开启")
        } else {
            print("⚠️ 蓝牙不可用，当前状态: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, !name.isEmpty else { return }
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }

        let devicesList = discoveredPeripherals
            .filter { $0.name != nil && !$0.name!.isEmpty }
            .map { ["name": $0.name!, "id": $0.identifier.uuidString] }

        devicesEventSink?(devicesList)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ 已连接设备: \(peripheral.name ?? "unknown")")
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ 连接失败: \(error?.localizedDescription ?? "未知错误")")
    }

    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("⚠️ 服务发现失败: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == serviceUUID {
                print("🔍 发现服务: \(service.uuid)")
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("⚠️ 特征发现失败: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                eegCharacteristic = characteristic

                // ⚠️ 延迟设置 notify（更安全）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("📡 已订阅 EEG 特征通知: \(characteristic.uuid)")
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ 接收数据错误: \(error.localizedDescription)")
            return
        }

        guard let value = characteristic.value else {
            print("⚠️ 数据为空")
            return
        }

        let data = [UInt8](value)
        print("📥 收到 EEG 数据: \(data)")

        eegEventSink?(data)
    }
}

// MARK: - Stream Handlers
class DeviceStreamHandler: NSObject, FlutterStreamHandler {
    private var setSink: (FlutterEventSink?) -> Void
    init(_ setSink: @escaping (FlutterEventSink?) -> Void) { self.setSink = setSink }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        setSink(events); return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        setSink(nil); return nil
    }
}

class EEGStreamHandler: NSObject, FlutterStreamHandler {
    private var setSink: (FlutterEventSink?) -> Void
    init(_ setSink: @escaping (FlutterEventSink?) -> Void) { self.setSink = setSink }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        setSink(events); return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        setSink(nil); return nil
    }
}
