import 'dart:async';
import 'package:flutter/services.dart';

class CoreMLService {
  static const platform = MethodChannel('coreml_channel');
  static const eventChannel = EventChannel('coreml_events');
  static StreamController<Map<String, dynamic>>? _resultController;
  static Stream<Map<String, dynamic>> get coremlResultStream {
    if (_resultController == null || _resultController!.isClosed) {
      _resultController = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _resultController!.stream;
  }

  static Future<void> initialize() async {
    try {
      // 模型已经在应用启动时加载，这里只需要返回成功
      print("✅ CoreML 已就绪");
    } catch (e) {
      print("❌ CoreML 初始化失败: $e");
    }
  }

  static void startPrediction() {
    try {
      platform.invokeMethod('startPrediction');
      print("▶️ 开始预测");
    } catch (e) {
      print("❌ 启动预测失败: $e");
    }
  }

  static void stopPrediction() {
    try {
      platform.invokeMethod('stopPrediction');
      print("⏹️ 停止预测");
    } catch (e) {
      print("❌ 停止预测失败: $e");
    }
  }

  static Future<void> switchModel(String modelName) async {
    try {
      await platform.invokeMethod('switchModel', {'modelName': modelName});
      print("🔄 切换到模型: $modelName");
    } catch (e) {
      print("❌ 切换模型失败: $e");
    }
  }

  static void setupEventChannel() {
    eventChannel.receiveBroadcastStream().listen((event) {
      print("📡 收到CoreML事件: $event");
      if (event is Map) {
        final Map<String, dynamic> result = {
          "data": List<double>.from(event["data"] ?? []),
          "stress": event["stress"] ?? "Unknown",
          "probability": (event["probability"] as num?)?.toDouble() ?? 0.0,
        };
        if (_resultController != null && !_resultController!.isClosed) {
          _resultController!.add(result);
        }
      }
    }, onError: (error) {
      print("❌ CoreML事件错误: $error");
    });
  }

  static void dispose() {
    _resultController?.close();
    _resultController = null;
  }
}
