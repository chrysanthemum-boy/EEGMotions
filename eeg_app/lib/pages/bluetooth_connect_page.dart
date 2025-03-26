import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/bluetooth_service.dart';

class BluetoothConnectPage extends StatefulWidget {
  const BluetoothConnectPage({super.key});

  @override
  State<BluetoothConnectPage> createState() => _BluetoothConnectPageState();
}

class _BluetoothConnectPageState extends State<BluetoothConnectPage> {
  String _status = "Disconnected";
  List<String> _logs = [];
  List<Map<String, String>> _devices = [];

  static const EventChannel _deviceStream = EventChannel("bluetooth_device_stream");

  @override
  void initState() {
    super.initState();
    _listenToScanResults();
  }

  void _listenToScanResults() {
    _deviceStream.receiveBroadcastStream().listen((event) {
      if (event is List) {
        final devices = event.map<Map<String, String>>((e) => {
          'name': e['name'] ?? "(no name)",
          'id': e['id'] ?? "",
        }).toList();

        setState(() {
          _devices = devices;
        });
      }
    }, onError: (err) {
      setState(() {
        _logs.add("❌ Error receiving device list: $err");
      });
    });
  }

  void _startScan() async {
    await BluetoothService.startScan();
    setState(() {
      _status = "Scanning...";
      _logs.add("Started scanning...");
    });
  }

  void _stopScan() async {
    await BluetoothService.stopScan();
    setState(() {
      _status = "Stopped scan";
      _logs.add("Stopped scanning.");
    });
  }

  void _connectTo(String deviceId) async {
    await BluetoothService.connectToDevice(deviceId);
    setState(() {
      _status = "Connected to $deviceId";
      _logs.add("Connected to $deviceId");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔵 Bluetooth Debug")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: $_status", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(onPressed: _startScan, child: const Text("Start Scan")),
                ElevatedButton(onPressed: _stopScan, child: const Text("Stop Scan")),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Nearby Devices:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return ListTile(
                    title: Text(device['name'] ?? "(no name)"),
                    subtitle: Text(device['id'] ?? ""),
                    trailing: ElevatedButton(
                      onPressed: () => _connectTo(device['id']!),
                      child: const Text("Connect"),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const Text("Logs:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(_logs[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
