// import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
// import '../service/coreml_service.dart';
import '../service/bluetooth_service.dart';

// class MonitorProvider extends ChangeNotifier {
//   String _status = "Loading...";
//   double _stressValue = 0.0;
//   bool _voiceEnabled = false;

//   String get status => _status;
//   double get stressValue => _stressValue;
//   bool get voiceEnabled => _voiceEnabled;

//   void toggleVoice() {
//     _voiceEnabled = !_voiceEnabled;
//     notifyListeners();
//   }

//   Future<void> runPrediction() async {
//     List<double> eegInput = List.generate(16000, (_) => Random().nextDouble());
//     String result = await CoreMLService.runPrediction(eegInput);

//     if (result == "Stress" || result == "Relaxed") {
//       _status = result;
//       _stressValue = result == "Stress" ? 0.85 : 0.12;
//       notifyListeners();
//     } else {
//       _status = "Error";
//       notifyListeners();
//     }
//   }
// }


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

  // void startListening() {
  //   BluetoothService.eegDataStream.listen((data) {
  //     if (data.length == channelCount) {
  //       addEEGSample(data);
  //     }
  //   });
  // }

  /// ✅ 新增：更新状态和概率（由 coremlResultStream 触发）
  void updatePrediction(String status, double probability) {
    _status = status;
    _stressValue = probability.clamp(0.0, 1.0);
    notifyListeners();
  }  
  
  /// ✅ 新增：模拟预测结果（用于调试或 UI 展示）
  void simulatePrediction() {
    final probability = (0.5 + 0.5 * (DateTime.now().second % 10) / 10).clamp(0.0, 1.0);
    final label = probability > 0.5 ? "Stress" : "Relaxed";
    updatePrediction(label, probability);
  }

  void reset() {
    _status = "Loading...";
    _stressValue = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    // reset();
    super.dispose();
  }
}


