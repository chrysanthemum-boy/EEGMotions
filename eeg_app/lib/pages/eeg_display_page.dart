import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/eeg_provider.dart';
import '../service/bluetooth_service.dart';

class EEGDisplayPage extends StatefulWidget {
  const EEGDisplayPage({super.key});

  @override
  State<EEGDisplayPage> createState() => _EEGDisplayPageState();
}

class _EEGDisplayPageState extends State<EEGDisplayPage> with WidgetsBindingObserver {
  StreamSubscription? _eegSub;
  Timer? _simulationTimer;
  final bool _isSimulation = false; // 控制是否使用模拟数据
  final Random _random = Random();
  final int _displayWindowSize = 30; // 显示窗口大小

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startDataCollection();
  }

  void _startDataCollection() {
    final eegProvider = Provider.of<EEGProvider>(context, listen: false);

    if (_isSimulation) {
      // 模拟数据生成
      _simulationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!mounted) return;
        final simulatedData = List.generate(16, (i) {
          // 生成模拟的EEG数据，包含一些随机波动和周期性变化
          final baseValue = 1000.0 + i * 100.0; // 基础值
          final noise = _random.nextDouble() * 200 - 100; // 随机噪声
          final sineWave = sin(DateTime.now().millisecondsSinceEpoch / 500.0) * 100; // 正弦波
          return baseValue + noise + sineWave;
        });
        eegProvider.addEEGData(simulatedData);
      });
    } else {
      // 真实蓝牙数据
      _eegSub = BluetoothService.eegDataStream.listen((decoded) {
        if (!mounted) return;
        if (decoded.length == 16) {
          eegProvider.addEEGData(decoded);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台时重新开始数据收集
      _startDataCollection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eegSub?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "📈 EEG Display",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("EEG Display Info"),
                  content: Text(
                    _isSimulation
                        ? "Currently displaying simulated EEG data for demonstration purposes."
                        : "Displaying real-time EEG data from the connected device.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
        child: Consumer<EEGProvider>(
          builder: (context, eeg, _) {
            final history = eeg.history;
            if (history.isEmpty || history.every((ch) => ch.isEmpty)) {
              return Center(
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
                      _isSimulation
                          ? "Starting simulation..."
                          : "Please connect to an EEG device",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 使用滑动窗口限制显示的数据量
            final windowedHistory = history.map((channelData) {
              final dataList = channelData.toList();
              final startIndex = max(0, dataList.length - _displayWindowSize);
              return dataList.sublist(startIndex);
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: windowedHistory.length,
              itemBuilder: (context, index) {
                final chData = windowedHistory[index];
                return EEGChartWidget(
                  channel: index + 1,
                  data: List<double>.from(chData),
                  isSimulation: _isSimulation,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class EEGChartWidget extends StatelessWidget {
  final int channel;
  final List<double> data;
  final bool isSimulation;

  const EEGChartWidget({
    super.key,
    required this.channel,
    required this.data,
    required this.isSimulation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Text(
                  "Channel $channel",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (isSimulation)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Simulation",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(
                  data,
                  lineColor: Colors.blue.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _LineChartPainter(this.data, {this.lineColor = Colors.indigo});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // 添加背景网格
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 绘制水平网格线
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 绘制垂直网格线
    for (int i = 0; i <= 4; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    final path = Path();
    final double dxStep = size.width / (data.length - 1);

    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal).toDouble();
    final double padding = range * 0.1;

    final double adjustedMin = minVal - padding;
    final double adjustedMax = maxVal + padding;

    for (int i = 0; i < data.length; i++) {
      final x = i * dxStep;
      final y = size.height - ((data[i] - adjustedMin) / (adjustedMax - adjustedMin)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

