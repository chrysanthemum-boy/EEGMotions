import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider/monitor_provider.dart';
import '../provider/eeg_provider.dart';
import '../service/coreml_service.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  StreamSubscription? _coremlSub;
  late Timer _timer;
  static const MethodChannel _voiceChannel = MethodChannel('accessibility_channel');

  @override
  void initState() {
    super.initState();
    

    // 模拟推理（可替换为真实推理）
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      context.read<MonitorProvider>().simulatePrediction();
    });

    // 监听 CoreML 推理结果
    _coremlSub = CoreMLService.coremlResultStream.listen((event) {
      final provider = context.read<MonitorProvider>();
      final stress = event['stress'] ?? "Unknown";
      final prob = (event['probability'] ?? 0.0).toDouble();
      print(
          "🧠 Received CoreML result: stress=$stress, probability=${prob.toStringAsFixed(3)}"
      );
      provider.updatePrediction(stress, prob);
      if (provider.voiceEnabled && stress == "Stress") {
        _announce("Stress detected.");
      }
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
    _coremlSub?.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonitorProvider>();
    final eeg = context.watch<EEGProvider>();
    final relaxedValue = provider.status == "Relaxed" ? 0.0 : provider.stressValue;
    final dynamicColor = Color.lerp(Colors.blueAccent, Colors.redAccent, relaxedValue)!;
    final circleSize = 160.0 + relaxedValue * 80;
    final isStress = provider.status == "Stress";
    final history = eeg.history;
    final isConnected = history.isNotEmpty && history.any((ch) => ch.isNotEmpty);
    var hasAnnounced = false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// 上半部分：圆圈动画（居中）
            Expanded(
              flex: 1,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _FlyingParticles(
                          count: 60,
                          color: dynamicColor,
                          startRadius: circleSize / 2,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      width: circleSize * 2,
                      height: circleSize * 2,
                      duration: const Duration(milliseconds: 600),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(relaxedValue * 0.5),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      width: circleSize,
                      height: circleSize,
                      duration: const Duration(milliseconds: 600),
                      decoration: BoxDecoration(
                        color: dynamicColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dynamicColor.withOpacity(0.6),
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
                  ],
                ),
              ),
            ),

            /// 下半部分：文字 & 按钮（居中）
            Expanded(
              flex: 1,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isConnected) ...[
                        // 👇 提示文字：未连接时显示
                        Text(
                          "Please connect the EEG device to start monitoring.",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // 👇 自动语音播报（只播报一次）
                        Builder(builder: (_) {
                          if (!hasAnnounced) {
                            Future.delayed(Duration.zero, () {
                              _announce("Please connect the EEG device to start monitoring.");
                              hasAnnounced = true;
                            });
                          }
                          return const SizedBox.shrink();
                        }),
                      ] else ...[
                        Text(
                          "Current Status: ",
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                          textAlign: TextAlign.center,
                          
                        ),
                        Text(
                          provider.status,
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: dynamicColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Stress Level: ${(relaxedValue * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _toggleVoice,
                          icon: Icon(provider.voiceEnabled ? Icons.volume_off : Icons.volume_up),
                          label: Text(provider.voiceEnabled
                              ? "Disable Voice Alert"
                              : "Enable Voice Alert"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlyingParticles extends StatefulWidget {
  final int count;
  final Color color;
  final double startRadius;

  const _FlyingParticles({
    required this.count,
    required this.color,
    required this.startRadius,
  });

  @override
  State<_FlyingParticles> createState() => _FlyingParticlesState();
}

class _FlyingParticlesState extends State<_FlyingParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _generateParticle());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  _Particle _generateParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = 30 + _random.nextDouble() * 40;
    final radius = widget.startRadius; // 从圆圈外圈开始
    final life = 0.5 + _random.nextDouble() * 0.5;

    return _Particle(
      angle: angle,
      speed: speed,
      radius: radius,
      life: life,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _RadialParticlePainter(
              particles: _particles,
              progress: _controller.value,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double radius;
  final double life;

  _Particle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.life,
  });
}

class _RadialParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _RadialParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      final t = (progress / p.life) % 1.0;
      final distance = p.radius + p.speed * t;
      final dx = cos(p.angle) * distance;
      final dy = sin(p.angle) * distance;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(center + Offset(dx, dy), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

