import Flutter
import UIKit
import CoreML
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate {
  var bluetoothManager: BluetoothManager?
  var coreMLModel: MLModel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // 在应用启动时自动加载 CoreML 模型
    do {
      let modelURL = Bundle.main.url(forResource: "eeg_model", withExtension: "mlmodelc")!
      coreMLModel = try MLModel(contentsOf: modelURL)
      print("✅ CoreML 模型初始化成功")
    } catch {
      print("❌ CoreML 模型初始化失败: \(error.localizedDescription)")
    }
    
    // CoreML Method Channel
    let coremlChannel = FlutterMethodChannel(name: "coreml_channel", binaryMessenger: controller.binaryMessenger)
    coremlChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }
      
      switch call.method {
      case "initializeCoreML":
        // 模型已经在启动时加载，直接返回成功
        result(true)
      case "startPrediction":
        self.startPrediction(result: result)
      case "stopPrediction":
        self.stopPrediction(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    // CoreML Event Channel
    let coremlEventChannel = FlutterEventChannel(name: "coreml_events", binaryMessenger: controller.binaryMessenger)
    coremlEventChannel.setStreamHandler(CoreMLStreamHandler())
    
    // 注册 Bluetooth 通道
    registerBluetoothChannel(with: controller.binaryMessenger)

    // 注册语音播报通道
    registerAccessibilityChannel(with: controller.binaryMessenger)

    // 注册连接状态通道
    let connectionChannel = FlutterEventChannel(name: "connection_status", binaryMessenger: controller.binaryMessenger)
    connectionChannel.setStreamHandler(ConnectionStreamHandler())

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func initializeCoreML(result: @escaping FlutterResult) {
    do {
      // 使用 MLModel 而不是具体的模型类
      let modelURL = Bundle.main.url(forResource: "eeg_model", withExtension: "mlmodelc")!
      coreMLModel = try MLModel(contentsOf: modelURL)
      print("✅ CoreML 模型初始化成功")
      result(true)
    } catch {
      print("❌ CoreML 模型初始化失败: \(error.localizedDescription)")
      result(FlutterError(code: "INIT_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func startPrediction(result: @escaping FlutterResult) {
    print("▶️ 开始 EEG 预测")
    result(true)
  }

  private func stopPrediction(result: @escaping FlutterResult) {
    print("⏹ 停止 EEG 预测")
    result(true)
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

  // 注册语音播报
  private func registerAccessibilityChannel(with message: FlutterBinaryMessenger) {
    let accessibilityChannel = FlutterMethodChannel(name: "accessibility_channel", binaryMessenger: message)
    accessibilityChannel.setMethodCallHandler { call, result in
      if call.method == "speak",
        let args = call.arguments as? [String: Any],
        let message = args["message"] as? String {
          print("🔊 \(message)")
          UIAccessibility.post(notification: .announcement, argument: message)
          result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

// 连接状态流处理器
class ConnectionStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var timer: Timer?
  
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    // 每秒发送一次连接状态
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.eventSink?("connected") // 这里可以根据实际连接状态返回不同的值
    }
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    timer?.invalidate()
    timer = nil
    return nil
  }
}



