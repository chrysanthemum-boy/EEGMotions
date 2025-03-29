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

  /// ✅ 监听 EEGPi 设备传来的数据
  static Stream<List<int>> get eegDataStream =>
    _eegDataStream.receiveBroadcastStream().map((event) {
      final List<int> raw = List<int>.from(event);
      List<int> decoded = [];
      for (int i = 0; i < raw.length; i += 3) {
        decoded.add(decodeSigned24Bit(raw.sublist(i, i + 3)));
      }
      return decoded;
    });


  
}
int decodeSigned24Bit(List<int> bytes) {
  int val = (bytes[0] << 16) | (bytes[1] << 8) | bytes[2];
  if ((val & 0x800000) != 0) {
    val = val - 0x1000000; // 还原为负数
  }
  return val;
}

List<int> decode24BitSamples(List<int> rawBytes) {
  List<int> result = [];

  for (int i = 0; i < rawBytes.length; i += 3) {
    if (i + 2 >= rawBytes.length) break;

    // 组合 3 字节为一个 24 位整数
    int value = (rawBytes[i] << 16) | (rawBytes[i + 1] << 8) | rawBytes[i + 2];

    // ⚠️ 如果你是 signed 24-bit，可以做 sign 扩展：
    if ((value & 0x800000) != 0) {
      value |= 0xFF000000; // 补符号位
      value = value.toSigned(32); // Dart 自动处理负数
    }
    result.add(value);
  }

  return result;
}