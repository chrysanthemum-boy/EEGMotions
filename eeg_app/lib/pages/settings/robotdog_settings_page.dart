import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/robotdog_provider.dart';

class RobotDogSettingsPage extends StatelessWidget {
  const RobotDogSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RobotDogProvider>(context);
    final options = ['Freeze', 'Get Closer', 'Stand Up'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Robot Dog Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 启用开关
            SwitchListTile(
              title: const Text('Enable Robot Dog Reaction'),
              value: provider.enabled,
              onChanged: (value) {
                provider.setEnabled(value);
              },
            ),
            const SizedBox(height: 16),

            // 🔘 模式选择（仅启用时显示）
            if (provider.enabled) ...[
              const Text(
                'Select Reaction Mode:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...options.map((mode) {
                return RadioListTile<String>(
                  title: Text(mode),
                  value: mode,
                  groupValue: provider.mode,
                  onChanged: (val) {
                    if (val != null) {
                      provider.setMode(val);
                    }
                  },
                );
              }).toList(),
            ],

            // const Spacer(),
            SizedBox(height: 40),

            // ✅ 保存设置
            if (provider.enabled)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Robot Dog mode set to "${provider.mode}".')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save Settings'),
                ),
              ),
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
