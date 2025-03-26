import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../service/coreml_service.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  String _status = "Loading...";
  double _stressValue = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    startMonitoring();
  }

  void startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      runEEGPredict();
    });
  }

  Future<void> runEEGPredict() async {
    // Simulate EEG input data (you can replace this with actual BLE-collected data)
    List<double> eegInput = List.generate(16000, (_) => Random().nextDouble());

    String result = await CoreMLService.runPrediction(eegInput);
    setState(() {
      if (result == "Stress" || result == "Relaxed") {
        _status = result;
        _stressValue = result == "Stress" ? 0.85 : 0.12; // Simulated value
      } else {
        _status = "Error";
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isStress = _status == "Stress";
    return Scaffold(
      // appBar: AppBar(title: const Text("🧠 Real-time Stress Monitoring")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                width: 160,
                height: 160,
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  color: isStress ? Colors.redAccent : Colors.blueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isStress ? Colors.redAccent.withOpacity(0.6) : Colors.blueAccent.withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    isStress ? "😖" : "😌",
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center, // 👈 横轴居中
                children: [
                  Text(
                    "Current Status: $_status",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // 👈 文本居中对齐（用于多行）
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Stress Level: ${(_stressValue * 100).toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
