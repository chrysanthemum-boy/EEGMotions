import Flutter
import UIKit
import CoreML
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate {
  var bluetoothManager: BluetoothManager?  // 👈 拿到全局作用域

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("❌ FlutterViewController not found")
    }

    // 注册 CoreML 通道
    registerCoreMLChannel(with: controller.binaryMessenger)

    // 注册 Bluetooth 通道
    registerBluetoothChannel(with: controller.binaryMessenger)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 📦 注册 CoreML 推理方法通道
  private func registerCoreMLChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "coreml_predictor", binaryMessenger: messenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "predict" {
        guard let args = call.arguments as? [String: Any],
              let input = args["input"] as? [Double] else {
          result(FlutterError(code: "INVALID_INPUT", message: "Expected input as [Double]", details: nil))
          return
        }

        if let prediction = predictEEG(inputData: input) {
          result(prediction)
        } else {
          result(FlutterError(code: "PREDICT_FAIL", message: "Prediction failed", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // 📡 注册蓝牙通道
  private func registerBluetoothChannel(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: "bluetooth_channel", binaryMessenger: messenger)

    bluetoothManager = BluetoothManager(messenger: messenger)

    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "startScan":
        self.bluetoothManager?.startScan()
        result(nil)
      case "stopScan":
        self.bluetoothManager?.stopScan()
        result(nil)
      case "connect":
        if let args = call.arguments as? [String: Any],
           let id = args["id"] as? String {
          self.bluetoothManager?.connectToPeripheral(id: id)
          result(nil)
        } else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing device ID", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}



