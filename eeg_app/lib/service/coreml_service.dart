import 'package:flutter/services.dart';

class CoreMLService {
  static const EventChannel _coremlStream = EventChannel("coreml_predictor");

  /// 实时监听 CoreML 推理结果（包括最后一帧 EEG 数据和预测标签）
  static Stream<Map<String, dynamic>> get coremlResultStream =>
      _coremlStream.receiveBroadcastStream().map((event) {
      final Map<String, dynamic> raw = Map<String, dynamic>.from(event);
      return {
        "data": List<double>.from(raw["data"] ?? []),
        "stress": raw["stress"] ?? "Unknown",
        "probability": (raw["probability"] as num?)?.toDouble() ?? 0.0,
      };
    });

}
