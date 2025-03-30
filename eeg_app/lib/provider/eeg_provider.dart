import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class EEGProvider extends ChangeNotifier {
  static const int channelCount = 16;
  static const int maxLength = 30;

  final List<List<double>> _history = List.generate(channelCount, (_) => []);

  List<List<double>> get history => _history;

  Timer? _simulationTimer;

  /// 添加来自 BLE 的 EEG 数据（16 通道）
  void addEEGData(List<double> data) {
    if (data.length != channelCount) return;

    for (int i = 0; i < channelCount; i++) {
      _history[i].add(data[i]);
      if (_history[i].length > maxLength) {
        _history[i].removeAt(0);
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
