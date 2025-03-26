import Flutter
import UIKit
import CoreML

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("❌ FlutterViewController not found")
    }

    let channel = FlutterMethodChannel(name: "coreml_predictor", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "predict" {
        // 🧠 获取输入数组
        guard let args = call.arguments as? [String: Any],
              let input = args["input"] as? [Double] else {
          result(FlutterError(code: "INVALID_INPUT", message: "Expected input as [Double]", details: nil))
          return
        }

        // 🔁 调用 CoreML 模型预测
        if let prediction = predictEEG(inputData: input) {
          result(prediction)
        } else {
          result(FlutterError(code: "PREDICT_FAIL", message: "Prediction failed", details: nil))
        }

      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// 🧠 EEGNet.mlpackage 推理函数
func predictEEG(inputData: [Double]) -> String? {
    guard inputData.count == 1000 * 16 else {
        print("❌ 输入维度错误")
        return nil
    }
    if #available(iOS 15.0, *) {
    do {
        let config = MLModelConfiguration()
        
            let model = try EEGNet(configuration: config)
            
            let inputArray = try MLMultiArray(shape: [1, 1000, 16], dataType: .float32)

            for i in 0..<1000 {
                for j in 0..<16 {
                    let index = i * 16 + j
                    inputArray[[0, NSNumber(value: i), NSNumber(value: j)]] = NSNumber(value: inputData[index])
                }
            }

            let modelInput = EEGNetInput(x_1: inputArray)
            let output = try model.prediction(input: modelInput)

            let rawValue = output.var_102[0].doubleValue  // 👈 自动生成的属性
            return rawValue > 0.5 ? "Stress" : "Relaxed"

       
    } catch {
        print("❌ 推理失败：\(error.localizedDescription)")
        return nil
    }
    } else {
        return nil
        // Fallback on earlier versions
    }
}


