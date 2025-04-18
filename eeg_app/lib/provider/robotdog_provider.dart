import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

class RobotDogProvider extends ChangeNotifier {
  bool _enabled = false;
  String _mode = 'Freeze';
  String _lastEmotion = "Relaxed";
  bool _isNotifying = false;
  String _status = "Inactive";
  String _stressAction = 'Follow';
  String _relaxAction = 'Freeze';

  // 基础主机地址
  static const String _baseUrl = "http://192.168.0.135:5000";
  
  // API路径映射
  final Map<String, String> _apiPaths = {
    'Freeze': "/api/freeze",
    'Follow': "/api/follow",
    'Play': "/api/play",
  };

  // 获取完整URL
  String get apiUrl => "$_baseUrl${_apiPaths[_mode] ?? '/api/freeze'}";

  bool get enabled => _enabled;
  String get mode => _mode;
  String get lastEmotion => _lastEmotion;
  bool get isNotifying => _isNotifying;
  String get status => _status;
  String get stressAction => _stressAction;
  String get relaxAction => _relaxAction;

  void setStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void setEnabled(bool val) {
    _enabled = val;
    notifyListeners();
  }

  void setMode(String newMode) {
    if (_apiPaths.containsKey(newMode)) {
      _mode = newMode;
      notifyListeners();
    }
  }

  void setStressAction(String action) {
    if (_apiPaths.containsKey(action)) {
      _stressAction = action;
      notifyListeners();
    }
  }

  void setRelaxAction(String action) {
    if (_apiPaths.containsKey(action)) {
      _relaxAction = action;
      notifyListeners();
    }
  }

  void updateEmotion(String emotion) {
    _lastEmotion = emotion;
    if (_enabled) {
      if (emotion == "Stress") {
        _mode = _stressAction;
        _sendStressNotification();
      } else {
        _mode = _relaxAction;
        _sendStressNotification();
      }
    }
    notifyListeners();
  }

  Future<void> _sendStressNotification() async {
    if (_isNotifying) return;
    
    _isNotifying = true;
    notifyListeners();

    // 使用 compute 在后台线程执行网络请求
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please check:\n1. Robot dog is powered on\n2. Connected to correct WiFi\n3. IP address is correct');
        },
      );
      
      if (response.statusCode != 200) {
        print("❌ Server returned error status code: HTTP ${response.statusCode}");
      }
    } on SocketException catch (e) {
      print("❌ Network connection error: ${e.message}");
    } on TimeoutException catch (e) {
      print("❌ $e");
    } catch (e) {
      print("❌ Unknown error occurred: $e");
    } finally {
      _isNotifying = false;
      notifyListeners();
    }
  }
}
