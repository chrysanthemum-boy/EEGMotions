import 'package:flutter/services.dart';

class BluetoothService {
  static const platform = MethodChannel('bluetooth_channel');

  static Future<void> startScan() async {
    try {
      await platform.invokeMethod('startScan');
    } catch (e) {
      print('❌ Failed to start scan: $e');
    }
  }

  static Future<void> stopScan() async {
    try {
      await platform.invokeMethod('stopScan');
    } catch (e) {
      print('❌ Failed to stop scan: $e');
    }
  }

  static Future<void> connectToDevice(String deviceId) async {
    try {
      await platform.invokeMethod('connect', {'id': deviceId});
    } catch (e) {
      print('❌ Failed to connect: $e');
    }
  }

  static const eegStream = EventChannel('bluetooth_data_stream');
}
