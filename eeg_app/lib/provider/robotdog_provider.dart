import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class RobotDogProvider extends ChangeNotifier {
  bool _enabled = false;
  String _mode = 'Freeze';
  String _lastEmotion = "Relaxed";
  bool _isNotifying = false;
  String _status = "Inactive";
  String _stressAction = 'dance';
  String _relaxAction = 'freeze';
  String _stopAction = 'stop';
  bool _robotConnected = false;
  bool _controllerInitialized = false;

  // 基础主机地址
  static const String _baseUrl = "http://192.168.12.248:5000";
  
  // API路径映射
  final Map<String, String> _apiPaths = {
    'Freeze': "/command/freeze",
    'Dance': "/command/dance",
    'Stop': "/command/stop",
  };

  // 获取完整URL
  String get apiUrl => "$_baseUrl/command";

  bool get enabled => _enabled;
  String get mode => _mode;
  String get lastEmotion => _lastEmotion;
  bool get isNotifying => _isNotifying;
  String get status => _status;
  String get stressAction => _stressAction;
  String get relaxAction => _relaxAction;
  bool get robotConnected => _robotConnected;
  bool get controllerInitialized => _controllerInitialized;

  void setStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void setEnabled(bool val) {
    _enabled = val;
    notifyListeners();
  }

  void setMode(String newMode) {
    // final lowerMode = newMode.toLowerCase();
    if (_apiPaths.containsKey(newMode)) {
      _mode = newMode;
      notifyListeners();
    }
  }

  void setStressAction(String action) {
    // if (_apiPaths.containsKey(action)) {
      _stressAction = action;
      notifyListeners();
    // }
  }

  void setRelaxAction(String action) {
    // if (_apiPaths.containsKey(action)) {
      _relaxAction = action;
      notifyListeners();
    // }
  }

  void updateEmotion(String emotion) {
    _lastEmotion = emotion;
    if (_enabled) {
      if (emotion == "Stress") {
        setCommand(_stressAction);
      } else if (emotion == "Relaxed") {
        setCommand(_relaxAction);
      } else if (emotion == "Stop") {
        setCommand(_stopAction);
      }
    }
    notifyListeners();
  }


  Future<void> setCommand(String command) async {
    if (!_enabled) return;
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'command': command}),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _mode = command;
          notifyListeners();
        }
      } else {
        print("❌ Failed to set command: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error setting command: $e");
    }
  }

  Future<void> fetchStatus() async {
    if (!_enabled) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _robotConnected = data['robot_connected'] ?? false;
        _controllerInitialized = data['controller_initialized'] ?? false;
        if (data['current_command'] != null) {
          _mode = data['current_command'];
        }
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error fetching status: $e");
    }
  }
}
