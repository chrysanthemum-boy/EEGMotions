// import 'package:flutter/material.dart';

// /// 设备信息模型
// class BluetoothDevice {
//   final String id;
//   final String name;

//   BluetoothDevice({required this.id, required this.name});
// }

// /// 蓝牙状态 Provider
// class BluetoothProvider extends ChangeNotifier {
//   // 🔹 设备列表
//   final List<BluetoothDevice> _devices = [];
//   List<BluetoothDevice> get devices => _devices;

//   // 🔹 当前扫描状态
//   bool _scanning = false;
//   bool get isScanning => _scanning;

//   // 🔹 已连接的设备 ID
//   String? _connectedDeviceId;
//   String? get connectedDeviceId => _connectedDeviceId;

//   // 🔹 EEG 数据（16 通道）
//   List<int> _eegData = [];
//   List<int> get eegData => _eegData;

//   // 🔹 日志信息
//   final List<String> _logs = [];
//   List<String> get logs => _logs;

//   /// 开始扫描设备
//   void startScan() {
//     _scanning = true;
//     _devices.clear();
//     notifyListeners();
//   }

//   /// 停止扫描设备
//   void stopScan() {
//     _scanning = false;
//     notifyListeners();
//   }

//   /// 添加新设备（避免重复 & 过滤无名）
//   void addDevice(String id, String name) {
//     if (name == "unknown" || name == "(no name)" || name.trim().isEmpty) return;

//     final exists = _devices.any((d) => d.id == id);
//     if (!exists) {
//       _devices.add(BluetoothDevice(id: id, name: name));
//       notifyListeners();
//     }
//   }

//   /// 清除所有设备列表
//   void clearDevices() {
//     _devices.clear();
//     notifyListeners();
//   }

//   /// 设置连接成功的设备
//   void setConnectedDevice(String id) {
//     _connectedDeviceId = id;
//     notifyListeners();
//   }

//   /// 更新 EEG 数据（16 通道）
//   void updateEEGData(List<int> data) {
//     _eegData = data;
//     notifyListeners();
//   }

//   /// 添加日志
//   void addLog(String log) {
//     _logs.add(log);
//     notifyListeners();
//   }
// }
import 'package:flutter/material.dart';

class BluetoothDevice {
  final String id;
  final String name;

  BluetoothDevice({required this.id, required this.name});
}

class BluetoothProvider extends ChangeNotifier {
  final List<BluetoothDevice> _devices = [];
  bool _scanning = false;
  String? _connectedDeviceId;
  final List<String> _logs = [];

  List<BluetoothDevice> get devices => _devices;
  bool get isScanning => _scanning;
  String? get connectedDeviceId => _connectedDeviceId;
  List<String> get logs => _logs;

  void startScan() {
    _scanning = true;
    _devices.clear();
    notifyListeners();
  }

  void stopScan() {
    _scanning = false;
    notifyListeners();
  }

  void addDevice(String id, String name) {
    if (name == "unknown" || name == "(no name)" || name.isEmpty) return;
    final exists = _devices.any((d) => d.id == id);
    if (!exists) {
      _devices.add(BluetoothDevice(id: id, name: name));
      notifyListeners();
    }
  }

  void setConnectedDevice(String id) {
    _connectedDeviceId = id;
    notifyListeners();
  }

  void addLog(String log) {
    _logs.add(log);
    notifyListeners();
  }

  void clear() {
    _devices.clear();
    _logs.clear();
    _connectedDeviceId = null;
    _scanning = false;
    notifyListeners();
  }
}