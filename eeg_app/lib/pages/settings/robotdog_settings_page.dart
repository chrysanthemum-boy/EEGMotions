import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/robotdog_provider.dart';

class RobotDogSettingsPage extends StatelessWidget {
  const RobotDogSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RobotDogProvider>(context);
    final modeOptions = [
      {'mode': 'Freeze', 'icon': Icons.pause_circle_outline},
      {'mode': 'Dance', 'icon': Icons.music_note},
      {'mode': 'Stop', 'icon': Icons.stop_circle_outlined},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🤖 Robot Dog Settings',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 🟢 Enable Switch Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.smart_toy, size: 30, color: Colors.blue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Robot Dog Reaction',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.enabled ? 'Enabled' : 'Disabled',
                                  style: TextStyle(
                                    color: provider.enabled ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: provider.enabled,
                            onChanged: (value) {
                              provider.setEnabled(value);
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔘 Mode Selection (only shown when enabled)
                  if (provider.enabled) ...[
                    const Text(
                      'Select Reaction Mode:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...modeOptions.map((option) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(option['icon'] as IconData, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(option['mode'] as String),
                            ],
                          ),
                          value: option['mode'] as String,
                          groupValue: provider.mode,
                          onChanged: (val) {
                            if (val != null) {
                              provider.setMode(val);
                            }
                          },
                          activeColor: Colors.blue,
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 24),

                    // Stress Action Selection
                    const Text(
                      'When Stress:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.stressAction,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                provider.setStressAction(newValue);
                              }
                            },
                            items: modeOptions.map<DropdownMenuItem<String>>((option) {
                              return DropdownMenuItem<String>(
                                value: (option['mode'] as String).toLowerCase(),
                                child: Row(
                                  children: [
                                    Icon(option['icon'] as IconData, color: Colors.red),
                                    const SizedBox(width: 12),
                                    Text(option['mode'] as String),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Relax Action Selection
                    const Text(
                      'When Relaxed:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.relaxAction,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                            style: const TextStyle(color: Colors.green, fontSize: 16),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                provider.setRelaxAction(newValue);
                              }
                            },
                            items: modeOptions.map<DropdownMenuItem<String>>((option) {
                              return DropdownMenuItem<String>(
                                value: (option['mode'] as String).toLowerCase(),
                                child: Row(
                                  children: [
                                    Icon(option['icon'] as IconData, color: Colors.green),
                                    const SizedBox(width: 12),
                                    Text(option['mode'] as String),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ✅ Save Settings Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // 保存设置并显示提示
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Robot Dog mode set to "${provider.mode}"'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          
                          // 测试连接
                          // if (provider.enabled) {
                          //   provider.updateEmotion("Stress"); // 触发测试连接
                          // }
                          
                          Navigator.pop(context);
                        },
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
                        child: const Text(
                          'Save Settings',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
