import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/bluetooth_service.dart';
import '../provider/bluetooth_provider.dart';

class BluetoothConnectPage extends StatefulWidget {
  const BluetoothConnectPage({super.key});

  @override
  State<BluetoothConnectPage> createState() => _BluetoothConnectPageState();
}

class _BluetoothConnectPageState extends State<BluetoothConnectPage> {
  StreamSubscription? _deviceSub;

  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    _deviceSub = BluetoothService.devicesStream.listen((devices) {
      if (!mounted) return;
      for (var device in devices) {
        bluetoothProvider.addDevice(device['id'], device['name']);
      }
    });
  }

  Future<void> _connectTo(String deviceId) async {
    final provider = Provider.of<BluetoothProvider>(context, listen: false);
    try {
      await BluetoothService.connectToDevice(deviceId);
      provider.setConnectedDevice(deviceId);
      provider.addLog("Connected to $deviceId");

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("✅ Connected"),
            content: Text("Successfully connected to $deviceId"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      provider.addLog("❌ Connection failed to $deviceId");
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("❌ Connection Failed"),
            content: Text("Could not connect to $deviceId.\\nError: \$e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              bluetooth.isScanning
                  ? "Status: Scanning..."
                  : "Status: ${bluetooth.connectedDeviceId != null ? 'Connected to ${bluetooth.connectedDeviceId}' : 'Disconnected'}",
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text("Nearby Devices:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bluetooth.devices.length,
              itemBuilder: (context, index) {
                final device = bluetooth.devices[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.id),
                    trailing: ElevatedButton(
                      onPressed: () => _connectTo(device.id),
                      child: const Text("Connect"),
                    ),
                  ),
                );
              },
            ),
          ),
          ExpansionTile(
            title: const Text("📜 Logs", style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bluetooth.logs.map((log) => Text(log)).toList(),
                ),
              )
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  BluetoothService.startScan();
                  context.read<BluetoothProvider>().startScan();
                },
                icon: const Icon(Icons.search),
                label: const Text("Start Scan"),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                BluetoothService.stopScan();
                context.read<BluetoothProvider>().stopScan();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300),
              child: const Text("Stop"),
            ),
          ],
        ),
      ),
    );
  }
}