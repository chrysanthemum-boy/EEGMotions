import CoreML

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