import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/robotdog_provider.dart';

class RobotDogSettingsPage extends StatelessWidget {
  const RobotDogSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RobotDogProvider>(context);
    final options = [
      {'mode': 'Freeze', 'icon': Icons.pause_circle_outline},
      {'mode': 'Get Closer', 'icon': Icons.directions_walk},
      {'mode': 'Stand Up', 'icon': Icons.vertical_align_top},
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                ...options.map((option) {
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
              ],

              const Spacer(),

              // ✅ Save Settings Button
              if (provider.enabled)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Robot Dog mode set to "${provider.mode}"'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
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
          ),
        ),
      ),
    );
  }
}
