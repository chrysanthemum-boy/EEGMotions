import 'dart:math';
import 'package:flutter/material.dart';
import '../service/coreml_service.dart';

class MonitorProvider extends ChangeNotifier {
  String _status = "Loading...";
  double _stressValue = 0.0;
  bool _voiceEnabled = false;

  String get status => _status;
  double get stressValue => _stressValue;
  bool get voiceEnabled => _voiceEnabled;

  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    notifyListeners();
  }

  Future<void> runPrediction() async {
    List<double> eegInput = List.generate(16000, (_) => Random().nextDouble());
    String result = await CoreMLService.runPrediction(eegInput);

    if (result == "Stress" || result == "Relaxed") {
      _status = result;
      _stressValue = result == "Stress" ? 0.85 : 0.12;
      notifyListeners();
    } else {
      _status = "Error";
      notifyListeners();
    }
  }
}
