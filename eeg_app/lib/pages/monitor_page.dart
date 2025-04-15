import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider/monitor_provider.dart';
import '../provider/eeg_provider.dart';
import '../service/coreml_service.dart';
import 'settings/bluetooth_connect_page.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  StreamSubscription? _coremlSub;
  StreamSubscription? _connectionSub;
  late Timer _timer;
  static const MethodChannel _voiceChannel = MethodChannel('accessibility_channel');
  static const EventChannel _connectionChannel = EventChannel('connection_status');

  @override
  void initState() {
    super.initState();
    
    // 初始化 CoreML 服务
    CoreMLService.initialize();
    CoreMLService.setupEventChannel();
    
    // 监听连接状态
    _connectionSub = _connectionChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final connected = event['connected'] as bool;
        final deviceName = event['device_name'] as String;
        
        if (connected) {
          // 连接成功，更新状态并开始预测
          context.read<EEGProvider>().setConnected(true);
          context.read<MonitorProvider>().setDeviceName(deviceName);
          CoreMLService.startPrediction();
          
          // 显示连接成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已连接到 $deviceName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // 断开连接，更新状态并停止预测
          context.read<EEGProvider>().setConnected(false);
          context.read<MonitorProvider>().setDeviceName(null);
          CoreMLService.stopPrediction();
          
          // 显示断开连接提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('设备已断开连接'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
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
    _connectionSub?.cancel();
    CoreMLService.dispose();
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
    final isConnected = eeg.isConnected;
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
                          count: 40,
                          color: dynamicColor,
                          startRadius: circleSize / 2,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      width: circleSize * 2,
                      height: circleSize * 2,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(relaxedValue * 0.4),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      width: circleSize,
                      height: circleSize,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: dynamicColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dynamicColor.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
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
                        const SizedBox(height: 24),
                        // 👇 蓝牙连接按钮
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BluetoothConnectPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bluetooth, color: Colors.white),
                          label: const Text("Connect Device"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
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
                        // 👇 已连接状态显示
                        Text(
                          "Connected to:",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          provider.deviceName ?? "Unknown Device",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
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
  late List<_Particle> _particles;
  final Random _random = Random();
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _generateParticle());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(_FlyingParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startRadius != widget.startRadius) {
      _particles = List.generate(widget.count, (_) => _generateParticle());
    }
  }

  _Particle _generateParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = 20 + _random.nextDouble() * 30;
    final radius = widget.startRadius;
    final life = 0.3 + _random.nextDouble() * 0.3;
    final startTime = _random.nextDouble() * life; // 随机开始时间

    return _Particle(
      angle: angle,
      speed: speed,
      radius: radius,
      life: life,
      startTime: startTime,
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
          final currentProgress = _controller.value;
          if (currentProgress < _lastProgress) {
            // 当动画循环时，更新粒子的开始时间
            for (var i = 0; i < _particles.length; i++) {
              if (_particles[i].startTime > currentProgress) {
                _particles[i] = _generateParticle();
              }
            }
          }
          _lastProgress = currentProgress;

          return CustomPaint(
            painter: _RadialParticlePainter(
              particles: _particles,
              progress: currentProgress,
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
  final double startTime;

  _Particle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.life,
    required this.startTime,
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
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var p in particles) {
      final t = ((progress - p.startTime) / p.life) % 1.0;
      if (t < 0) continue; // 跳过还未开始的粒子
      
      final distance = p.radius + p.speed * t;
      final dx = cos(p.angle) * distance;
      final dy = sin(p.angle) * distance;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      paint.color = color.withOpacity(opacity * 0.7);
      canvas.drawCircle(center + Offset(dx, dy), 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(_RadialParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color;
  }
}

