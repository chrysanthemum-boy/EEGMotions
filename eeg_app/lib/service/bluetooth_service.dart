import 'package:flutter/services.dart';

class BluetoothService {
  static const MethodChannel _channel = MethodChannel('bluetooth_channel');
  static const EventChannel _deviceStream = EventChannel("bluetooth_device_stream");
  static const EventChannel _eegDataStream = EventChannel("eeg_data_stream"); // 👈 新增：接收EEG数据

  static Future<void> startScan() async {
    await _channel.invokeMethod('startScan');
  }

  static Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
  }

  static Future<void> connectToDevice(String id) async {
    await _channel.invokeMethod('connect', {"id": id});
  }

  /// ✅ 监听设备列表更新
  static Stream<List<Map<String, dynamic>>> get devicesStream =>
    _deviceStream.receiveBroadcastStream().map((event) {
      final List raw = event as List;
      return raw.map((e) => {
        "name": e["name"] ?? "unknown",
        "id": e["id"] ?? "",
      }).toList();
    });

/// ✅ 直接监听 Flutter 原生端推送的解码数据（List<double>）
  static Stream<List<double>> get eegDataStream =>
      _eegDataStream.receiveBroadcastStream().map((event) {
        return List<double>.from(event);
      });
  
}