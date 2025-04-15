import Foundation
import CoreML
import Flutter

// 全局变量
var eegBuffer: [[Double]] = []
var eegEventSink: FlutterEventSink?
var predictionTimer: Timer?

// 滑动窗口配置
let slidingWindowSize = 1000
let probabilityWindowSize = 15
let predictionWindowSize = 15
let stabilityThreshold = 5
let decisionThreshold = 0.5

var probabilityWindow: [Double] = []
var predictionWindow: [Int] = []
var lastPrediction: Int? = nil
var consecutiveSame = 0

class CoreMLStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eegEventSink = events
        print("🧠 CoreML 事件监听开始")

        predictionTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            predictEEG()
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eegEventSink = nil
        predictionTimer?.invalidate()
        predictionTimer = nil
        probabilityWindow.removeAll()
        predictionWindow.removeAll()
        lastPrediction = nil
        consecutiveSame = 0
        print("🧠 CoreML 事件监听取消")
        return nil
    }
}

// 数据处理：接收单帧 EEG 数据
func handleEEGData(_ data: [UInt8]) {
    guard data.count >= 48 else { return }

    var frame: [Double] = []
    for i in stride(from: 0, to: 48, by: 3) {
        let raw = (Int(data[i]) << 16) | (Int(data[i+1]) << 8) | Int(data[i+2])
        let signed = raw >= 0x800000 ? raw - 0x1000000 : raw
        frame.append(Double(signed))
    }

    eegBuffer.append(frame)
    if eegBuffer.count > slidingWindowSize {
        eegBuffer.removeFirst()
    }
}

// 主推理函数
func predictEEG() {
    guard let lastFrame = eegBuffer.last, lastFrame.count == 16 else {
        print("⏳ 等待最新帧数据中...")
        return
    }

    do {
        // 获取 AppDelegate 中的模型实例
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let model = appDelegate.coreMLModel else {
            print("❌ CoreML 模型未初始化")
            return
        }

        // 准备输入数据
        let inputArray = try MLMultiArray(shape: [1, 1, 16], dataType: .float32)
        for i in 0..<16 {
            inputArray[[0, 0, NSNumber(value: i)]] = NSNumber(value: lastFrame[i])
        }

        // 创建模型输入
        let input = try MLDictionaryFeatureProvider(dictionary: ["x_1": inputArray])
        
        // 执行预测
        let output = try model.prediction(from: input)
        let outputFeatures = output.featureValue(for: "var_135")?.multiArrayValue
        
        guard let outputArray = outputFeatures else {
            print("❌ 无法获取模型输出")
            return
        }

        // Softmax 概率计算
        let logit0 = outputArray[0].doubleValue
        let logit1 = outputArray[1].doubleValue
        let stressProb = exp(logit1) / (exp(logit0) + exp(logit1))

        // 更新滑动窗口
        probabilityWindow.append(stressProb)
        if probabilityWindow.count > probabilityWindowSize {
            probabilityWindow.removeFirst()
        }

        let avgProb = probabilityWindow.reduce(0, +) / Double(probabilityWindow.count)
        let predictedClass = avgProb > decisionThreshold ? 1 : 0

        predictionWindow.append(predictedClass)
        if predictionWindow.count > predictionWindowSize {
            predictionWindow.removeFirst()
        }

        let stressCount = predictionWindow.filter { $0 == 1 }.count
        let unstressCount = predictionWindow.count - stressCount
        let finalPrediction = stressCount > unstressCount ? 1 : 0
        let confidence = Double(max(stressCount, unstressCount)) / Double(predictionWindow.count)

        if lastPrediction == finalPrediction {
            consecutiveSame += 1
        } else {
            consecutiveSame = 0
        }
        lastPrediction = finalPrediction

        if consecutiveSame >= stabilityThreshold || predictionWindow.count < predictionWindowSize / 2 {
            let label = finalPrediction == 1 ? "Stress" : "Relaxed"
            print("✅ 稳定输出: \(label) (avgProb: \(avgProb), confidence: \(confidence))")
            eegEventSink?([
                "data": lastFrame,
                "stress": label,
                "probability": avgProb
            ])
        } else {
            print("⏳ 正在稳定中... (\(consecutiveSame + 1) 次相同预测)")
        }

    } catch {
        print("❌ 推理失败：\(error.localizedDescription)")
    }
} 