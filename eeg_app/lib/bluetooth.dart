import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  // 扫描设备
  void startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 5));
  }

  // 监听扫描结果
  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;

  // 停止扫描
  void stopScan() {
    flutterBlue.stopScan();
  }

  // 连接设备
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
  }

  // 断开设备
  Future<void> disconnectDevice(BluetoothDevice device) async {
    await device.disconnect();
  }
}
