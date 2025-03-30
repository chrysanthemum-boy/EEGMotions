import Foundation
import CoreML

var eegBuffer: [[Double]] = []
var eegEventSink: FlutterEventSink?

// 🕒 添加定时器
var predictionTimer: Timer?

class CoreMLStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eegEventSink = events
        print("🧠 CoreML 事件监听开始")

        // 🟢 开始每1秒推理一次
        predictionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if #available(iOS 15.0, *) {
                predictEEG(buffer: eegBuffer)
            }
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eegEventSink = nil
        predictionTimer?.invalidate()
        predictionTimer = nil
        print("🧠 CoreML 事件监听取消")
        return nil
    }
}

func handleEEGData(_ data: [UInt8]) {
    guard data.count >= 48 else { return }

    var frame: [Double] = []

    for i in stride(from: 0, to: 48, by: 3) {
        let raw = (Int(data[i]) << 16) | (Int(data[i+1]) << 8) | Int(data[i+2])
        let signed = raw >= 0x800000 ? raw - 0x1000000 : raw
        frame.append(Double(signed))
    }

    eegBuffer.append(frame)

    // 保持最多 1000 帧
    if eegBuffer.count > 1000 {
        eegBuffer.removeFirst()
    }
}

@available(iOS 15.0, *)
func predictEEG(buffer: [[Double]]) {
    guard buffer.count == 1000 else {
        print("⏳ 等待满 1000 帧，当前仅 \(buffer.count)")
        return
    }

    do {
        let model = try EEGNet(configuration: .init())
        let inputArray = try MLMultiArray(shape: [1, 1000, 16], dataType: .float32)

        for i in 0..<1000 {
            for j in 0..<16 {
                inputArray[[0, NSNumber(value: i), NSNumber(value: j)]] = NSNumber(value: buffer[i][j])
            }
        }

        let input = EEGNetInput(x_1: inputArray)
        let output = try model.prediction(input: input)

        let probability = output.var_102[0].doubleValue
        let label = probability > 0.5 ? "Stress" : "Relaxed"

        print("🧠 推理结果：\(label) (\(probability))")

        eegEventSink?([
            "data": buffer.last ?? [],
            "stress": label,
            "probability": probability
        ])
    } catch {
        print("❌ 推理失败：\(error.localizedDescription)")
    }
}
