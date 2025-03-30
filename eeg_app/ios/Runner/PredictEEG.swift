import CoreBluetooth
import CoreML

// 全局缓存，用于收集 1000 条连续 EEG 数据帧（每帧 16 通道）
var eegBuffer: [[Double]] = []

var eegEventSink: FlutterEventSink?

func handleEEGData(_ data: [UInt8]) {
    guard data.count >= 48 else {
        print("❌ 数据不足 48 字节")
        return
    }

    var frame: [Double] = []

    // 解码 16 通道（每 3 字节一个 24-bit 补码数）
    for i in stride(from: 0, to: 48, by: 3) {
        let raw = (Int(data[i]) << 16) | (Int(data[i+1]) << 8) | Int(data[i+2])
        let signed = raw >= 0x800000 ? raw - 0x1000000 : raw  // 补码还原
        frame.append(Double(signed))
    }

    eegBuffer.append(frame)

    // 限制缓存大小：只保留最新 1000 帧
    if eegBuffer.count > 1000 {
        eegBuffer.removeFirst()
    }

    // 推理条件：满 1000 帧
    if eegBuffer.count == 1000 {
        if #available(iOS 15.0, *) {
            predictEEG(buffer: eegBuffer)
        } else {
            // Fallback on earlier versions
        }

        // 🔁 推理后可选择清空或滑动窗口
        // eegBuffer.removeAll()           // 若按段推理
        // eegBuffer.removeFirst(50)       // 若滑窗推理（滑动 50 帧）
    }
}

@available(iOS 15.0, *)
func predictEEG(buffer: [[Double]]) {

    guard buffer.count == 1000 && buffer[0].count == 16 else {
        print("❌ EEG 输入格式不正确")
        return
    }

    do {
        let model = try EEGNet(configuration: .init())
        let inputArray = try MLMultiArray(shape: [1, 1000, 16], dataType: .float32)

        for i in 0..<1000 {
            for j in 0..<16 {
                let index: [NSNumber] = [0, NSNumber(value: i), NSNumber(value: j)]
                inputArray[index] = NSNumber(value: buffer[i][j])
            }
        }

        let input = EEGNetInput(x_1: inputArray)
        let output = try model.prediction(input: input)

        let probability = output.var_102[0].doubleValue
        let label = probability > 0.5 ? "Stress" : "Relaxed"

        print("🧠 推理结果：\(label) (\(probability))")

        // ✅ 推送到 Flutter（需要封装 JSON 结构）
        eegEventSink?([
            "data": buffer.last ?? [],
            "stress": label,
            "probability": probability
        ])


    } catch {
        print("❌ CoreML 推理失败：\(error.localizedDescription)")
    }
}

class CoreMLStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eegEventSink = events // 👈 设置全局用于推理结果输出
        print("🧠 CoreML 事件监听开始")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eegEventSink = nil
        print("🧠 CoreML 事件监听取消")
        return nil
    }
}
