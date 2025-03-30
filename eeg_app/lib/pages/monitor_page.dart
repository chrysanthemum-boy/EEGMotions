import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider/monitor_provider.dart';
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
    // _timer = Timer.periodic(const Duration(seconds: 2), (_) {
    //   context.read<MonitorProvider>().simulatePrediction();
    // });
    // 监听 CoreML 推理结果
    _coremlSub = CoreMLService.coremlResultStream.listen((event) {
      final provider = context.read<MonitorProvider>();
      final stress = event['stress'] ?? "Unknown";
      final prob = (event['probability'] ?? 0.0).toDouble();

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
    final stressValue = provider.stressValue;
    final isStress = provider.status == "Stress";

    final dynamicColor = Color.lerp(Colors.blueAccent, Colors.redAccent, stressValue)!;
    final circleSize = 160.0 + stressValue * 40;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🌈 Stack 中对齐两个动画层：光圈 + 主圆
              Stack(
                alignment: Alignment.center,
                children: [
                  // ✅ ✨发散粒子层（最上面！可见）
                  Positioned.fill(
                    child: IgnorePointer( // 确保不影响交互
                      child: _FlyingParticles(
                        count: 60,
                        color: const Color.fromARGB(179, 240, 2, 2),
                        startRadius: circleSize / 2,
                      ),
                    ),
                  ),

                  // 🌈 白色渐变扩散光圈
                  AnimatedContainer(
                    width: circleSize * 2,
                    height: circleSize * 2,
                    duration: const Duration(milliseconds: 600),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(stressValue * 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  // _FlyingParticles(color: dynamicColor.withOpacity(0.5), count: 20),
                  // 🟠 中心圆圈（变色、变大）
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


              const SizedBox(height: 32),
              Text(
                "Current Status: ${provider.status}",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Stress Level: ${(stressValue * 100).toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 32),
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

