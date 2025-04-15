import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class MonitorProvider extends ChangeNotifier {
  String _status = "Relaxed";
  double _stressValue = 0.0;
  bool _voiceEnabled = false;
  String? _deviceName;

  String get status => _status;
  double get stressValue => _stressValue;
  bool get voiceEnabled => _voiceEnabled;
  String? get deviceName => _deviceName;

  void updatePrediction(String status, double stressValue) {
    _status = status;
    _stressValue = stressValue;
    notifyListeners();
  }

  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    notifyListeners();
  }

  void setDeviceName(String? name) {
    _deviceName = name;
    notifyListeners();
  }

  static const int windowSize = 1000;
  static const int channelCount = 16;

  final List<Queue<double>> _buffers = List.generate(channelCount, (_) => Queue<double>());

  void addEEGSample(List<int> sample) {
    if (sample.length != channelCount) return;
    print(
        "Received sample: ${sample.map((e) => e.toString()).join(", ")}"
    );
    for (int i = 0; i < channelCount; i++) {
      _buffers[i].add(sample[i].toDouble());
      if (_buffers[i].length > windowSize) {
        _buffers[i].removeFirst();
      }
    }
  }

  void reset() {
    _status = "Loading...";
    _stressValue = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}


