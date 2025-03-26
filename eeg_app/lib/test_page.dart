import 'package:flutter/material.dart';
import 'coreml_service.dart';
import 'dart:math';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _result = "No prediction yet";

  void _runTest() async {
    List<double> eegInput = List.generate(16000, (_) => Random().nextDouble());
    String prediction = await CoreMLService.runPrediction(eegInput);

    setState(() {
      _result = prediction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("🧪 Single Prediction")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _result,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _runTest,
                child: const Text("Run EEG Prediction"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
