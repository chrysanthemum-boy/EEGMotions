import 'package:flutter/services.dart';

class CoreMLService {
  static const MethodChannel _channel = MethodChannel('coreml_predictor');

  static Future<String> runPrediction(List<double> input) async {
    try {
      final result = await _channel.invokeMethod<String>('predict', {
        'input': input,
      });
      return result ?? "Unknown";
    } catch (e) {
      return "Error: $e";
    }
  }
}
