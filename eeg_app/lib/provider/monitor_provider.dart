import 'dart:collection';
// import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class MonitorProvider extends ChangeNotifier {
  String _status = "Relaxed";
  double _stressValue = 0.0;
  bool _voiceEnabled = false;
  String? _deviceName;
  bool _isLoading = false;
  String _currentModel = "eeg_model";

  String get status => _status;
  double get stressValue => _stressValue;
  bool get voiceEnabled => _voiceEnabled;
  String? get deviceName => _deviceName;
  bool get isLoading => _isLoading;
  String get currentModel => _currentModel;

  void updatePrediction(String status, double stressValue) {
    if (_status != status || _stressValue != stressValue) {
      _status = status;
      _stressValue = stressValue;
      notifyListeners();
    }
  }

  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    notifyListeners();
  }

  void setDeviceName(String? name) {
    if (_deviceName != name) {
      _deviceName = name;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void switchModel(String modelName) {
    if (_currentModel != modelName) {
      _currentModel = modelName;
      notifyListeners();
    }
  }

  static const int windowSize = 1000;
  static const int channelCount = 16;

  final List<Queue<double>> _buffers = List.generate(channelCount, (_) => Queue<double>());

  void addEEGSample(List<int> sample) {
    if (sample.length != channelCount) {
      debugPrint("❌ EEG sample length mismatch: expected $channelCount, got ${sample.length}");
      return;
    }
    
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
    _isLoading = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _buffers.clear();
    super.dispose();
  }
}


