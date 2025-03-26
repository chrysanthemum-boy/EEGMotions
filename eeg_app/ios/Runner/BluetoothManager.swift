import Foundation
import CoreBluetooth
import Flutter

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral] = []
    private var eventSink: FlutterEventSink?
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        // 设置事件通道
        let eventChannel = FlutterEventChannel(name: "bluetooth_device_stream", binaryMessenger: messenger)
        eventChannel.setStreamHandler(self)
    }

    func startScan() {
        print("🔍 Start scanning...")
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScan() {
        print("🛑 Stop scanning")
        centralManager.stopScan()
    }

    func connectToPeripheral(id: String) {
        guard let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == id }) else {
            print("❌ Peripheral with ID \(id) not found")
            return
        }
        centralManager.connect(peripheral, options: nil)
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("✅ Bluetooth powered on")
        } else {
            print("⚠️ Bluetooth state: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            print("📡 Discovered: \(peripheral.name ?? "(no name)") - \(peripheral.identifier.uuidString)")
            sendDevicesToFlutter()
        }
    }

    private func sendDevicesToFlutter() {
        guard let sink = eventSink else { return }

        let devices = discoveredPeripherals.map { peripheral in
            return [
                "name": peripheral.name ?? "(no name)",
                "id": peripheral.identifier.uuidString
            ]
        }

        sink(devices)
    }
}

// MARK: - FlutterStreamHandler
extension BluetoothManager: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("📶 Flutter started listening for device stream")
        eventSink = events
        sendDevicesToFlutter() // Push any already scanned devices
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("❎ Flutter stopped listening for device stream")
        eventSink = nil
        return nil
    }
}
