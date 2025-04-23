// lib/pages/robot_dog_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/robotdog_provider.dart';
import '../provider/monitor_provider.dart';
import '../provider/eeg_provider.dart';
import 'settings/bluetooth_connect_page.dart';
import 'dart:async';

class RobotDogPage extends StatefulWidget {
  const RobotDogPage({super.key});

  @override
  State<RobotDogPage> createState() => _RobotDogPageState();
}

class _RobotDogPageState extends State<RobotDogPage> {
  bool _isInitialized = false;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() {
    if (!_isInitialized) {
      // 监听情绪变化
      final monitorProvider = Provider.of<MonitorProvider>(context, listen: false);
      monitorProvider.addListener(_onEmotionChanged);
      
      // 添加定时器实时更新状态
      _startStatusUpdateTimer();
      
      _isInitialized = true;
    }
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (mounted) {
        final robotDogProvider = Provider.of<RobotDogProvider>(context, listen: false);
        await robotDogProvider.fetchStatus();
        setState(() {});
      }
    });
  }

  void _onEmotionChanged() {
    if (!mounted) return;
    
    final monitorProvider = Provider.of<MonitorProvider>(context, listen: false);
    final robotDogProvider = Provider.of<RobotDogProvider>(context, listen: false);
    
    if (monitorProvider.status != robotDogProvider.lastEmotion) {
      robotDogProvider.updateEmotion(monitorProvider.status);
    }
  }

  @override
  void dispose() {
    final monitorProvider = Provider.of<MonitorProvider>(context, listen: false);
    monitorProvider.removeListener(_onEmotionChanged);
    _statusUpdateTimer?.cancel();
    _isInitialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final robotDog = context.watch<RobotDogProvider>();
    final monitor = context.watch<MonitorProvider>();
    final eegProvider = context.watch<EEGProvider>();

    // 如果未连接 EEG 设备，显示提示信息
    if (!eegProvider.isConnected) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "🤖 Robot Dog Status",
            style: TextStyle(color: Colors.white),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.signal_wifi_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No EEG data available",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please connect to an EEG device",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BluetoothConnectPage()),
                    );
                  },
                  icon: const Icon(Icons.bluetooth, color: Colors.white),
                  label: const Text("Connect Device"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 已连接 EEG 设备时的正常界面
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🤖 Robot Dog Status",
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 状态卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pets,
                          size: 30,
                          color: monitor.status == "Stress" 
                              ? Colors.red 
                              : Colors.green,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Current Status",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              robotDog.mode,
                              style: TextStyle(
                                color: monitor.status == "Stress" 
                                    ? Colors.red 
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 30,
                          color: monitor.status == "Stress" 
                              ? Colors.red 
                              : Colors.green,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Real-time Emotion",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              monitor.status,
                              style: TextStyle(
                                color: monitor.status == "Stress" 
                                    ? Colors.red 
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 情绪状态指示器
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Emotion Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: monitor.status == "Stress" 
                            ? Colors.red.shade100 
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          monitor.status,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: monitor.status == "Stress" 
                                ? Colors.red 
                                : Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // API 状态
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "API Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "URL: ${robotDog.apiUrl}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Last Notification: ${monitor.status == "Stress" ? "Sent" : "Not Required"}",
                      style: TextStyle(
                        color: monitor.status == "Stress" 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          robotDog.enabled ? Icons.check_circle : Icons.cancel,
                          color: robotDog.enabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Robot Dog ${robotDog.enabled ? "Enabled" : "Disabled"}",
                          style: TextStyle(
                            color: robotDog.enabled ? Colors.green : Colors.red,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: robotDog.enabled,
                          onChanged: (value) {
                            robotDog.setEnabled(value);
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Current Mode: ${robotDog.mode}",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}