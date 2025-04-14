import 'package:flutter/material.dart';
import 'settings/bluetooth_connect_page.dart';
import 'settings/robotdog_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("Settings"),
        // centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60), // ⬅️ 放大按钮
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BluetoothConnectPage()),
                  );
                },
                icon: const Icon(Icons.bluetooth, size: 28),
                label: const Text("Bluetooth Connect"),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60), // ⬅️ 放大按钮
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RobotDogSettingsPage()),
                  );
                },
                icon: const Icon(Icons.smart_toy, size: 28),
                label: const Text("Robot Dog Settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
