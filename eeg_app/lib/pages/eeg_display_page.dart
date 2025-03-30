import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/eeg_provider.dart';
import '../service/bluetooth_service.dart';

class EEGDisplayPage extends StatefulWidget {
  const EEGDisplayPage({super.key});

  @override
  State<EEGDisplayPage> createState() => _EEGDisplayPageState();
}

class _EEGDisplayPageState extends State<EEGDisplayPage> {
  StreamSubscription? _eegSub;

  @override
  void initState() {
    super.initState();
    final eegProvider = Provider.of<EEGProvider>(context, listen: false);
    // eegProvider.startSimulation();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) _subscribeToBluetoothEEG();
    // });

    _eegSub = BluetoothService.eegDataStream.listen((decoded) {
      if (!mounted) return;
      if (decoded.length == 16) {
        eegProvider.addEEGData(decoded); // 直接传入即可
      }
    });
  }




  @override
  void dispose() {
    _eegSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("📈 EEG Chart")),
      body: Consumer<EEGProvider>(
        builder: (context, eeg, _) {
          final history = eeg.history;
          // final eegdata = eeg.eegData;
          if (history.isEmpty || history.every((ch) => ch.isEmpty)) {
            return const Center(child: Text("No EEG data yet..."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final chData = history[index];
              // return Center(child: Text(eegdata.toString()));
              return EEGChartWidget(channel: index + 1, data: List<int>.from(chData));
            },
          );
        },
      ),
    );
  }
}

class EEGChartWidget extends StatelessWidget {
  final int channel;
  final List<int> data;

  const EEGChartWidget({super.key, required this.channel, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CH$channel", style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(data),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> data;
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

    final path = Path();
    final double dxStep = size.width / (data.length - 1);

    // 🧠 自动计算最大最小值，加上 padding 避免挤边缘
    final int minVal = data.reduce((a, b) => a < b ? a : b);
    final int maxVal = data.reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal).toDouble();
    final double padding = range * 0.1; // 10% padding

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

