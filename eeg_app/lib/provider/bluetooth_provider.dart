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
  String? get connectedDeviceName {
    if (_connectedDeviceId == null) return null;
    final device = _devices.firstWhere((d) => d.id == _connectedDeviceId);
    return device.name;
  }
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
      final device = BluetoothDevice(id: id, name: name);
      if (name.toLowerCase().contains("eegpi")) {
        _devices.insert(0, device);
      } else {
        _devices.add(device);
      }
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