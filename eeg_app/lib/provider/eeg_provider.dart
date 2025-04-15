import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';

class EEGProvider extends ChangeNotifier {
  static const int channelCount = 16;
  static const int maxLength = 30;
  static const int maxHistoryLength = 1000;

  final List<Queue<double>> _history = List.generate(channelCount, (_) => Queue<double>());
  bool _isConnected = false;

  List<Queue<double>> get history => _history;
  bool get isConnected => _isConnected;

  Timer? _simulationTimer;

  /// 添加来自 BLE 的 EEG 数据（16 通道）
  void addEEGData(List<double> data) {
    if (data.length != channelCount) {
      print("❌ EEG数据长度错误: ${data.length} (期望$channelCount)");
      return;
    }
    
    print("📊 收到EEG数据: ${data.map((e) => e.toStringAsFixed(2)).join(", ")}");
    
    for (int i = 0; i < channelCount; i++) {
      _history[i].add(data[i]);
      if (_history[i].length > maxHistoryLength) {
        _history[i].removeFirst();
      }
    }
    notifyListeners();
  }

  /// 启动模拟 EEG 数据（调试使用）
  void startSimulation({Duration interval = const Duration(milliseconds: 500)}) {
    stopSimulation(); // 确保只启动一个 timer
    _simulationTimer = Timer.periodic(interval, (_) {
      final mock = List.generate(channelCount, (i) => 40 + i + Random().nextDouble());
      addEEGData(mock);
    });
  }

  /// 停止模拟
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  /// 清空历史数据
  void reset() {
    for (var queue in _history) {
      queue.clear();
    }
    notifyListeners();
  }

  void setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  void clearHistory() {
    for (int i = 0; i < channelCount; i++) {
      _history[i].clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}
