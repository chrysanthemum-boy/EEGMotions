import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider/monitor_provider.dart';
import '../service/bluetooth_service.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  late Timer _timer;
  static const MethodChannel _voiceChannel = MethodChannel('accessibility_channel');

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      context.read<MonitorProvider>().runPrediction().then((_) {
        final provider = context.read<MonitorProvider>();
        if (provider.voiceEnabled && provider.status == "Stress") {
          _announce("Stress detected.");
        }
      });
    });
  }

  void _announce(String message) {
    _voiceChannel.invokeMethod("speak", {"message": message});
  }

  void _toggleVoice() {
    final provider = context.read<MonitorProvider>();
    provider.toggleVoice();
    _announce(provider.voiceEnabled ? "Voice alert enabled" : "Voice alert disabled");
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonitorProvider>();
    final isStress = provider.status == "Stress";

    return Scaffold(
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
                      color: isStress
                          ? Colors.redAccent.withOpacity(0.6)
                          : Colors.blueAccent.withOpacity(0.6),
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
              Text(
                "Current Status: ${provider.status}",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Stress Level: ${(provider.stressValue * 100).toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // EEG 数据监听（可选）
              StreamBuilder<List<int>>(
                stream: BluetoothService.eegDataStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    print("📡 EEG Received: ${snapshot.data}");
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _toggleVoice,
                icon: Icon(provider.voiceEnabled ? Icons.volume_off : Icons.volume_up),
                label: Text(provider.voiceEnabled ? "Disable Voice Alert" : "Enable Voice Alert"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
