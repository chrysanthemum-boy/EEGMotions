import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/bluetooth_service.dart';
import '../../provider/bluetooth_provider.dart';
import '../../provider/eeg_provider.dart';
import '../../provider/monitor_provider.dart';
// import '../monitor_page.dart';

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
    final eegProvider = Provider.of<EEGProvider>(context, listen: false);
    final monitorProvider = Provider.of<MonitorProvider>(context, listen: false);
    
    final deviceName = provider.devices.firstWhere((device) => device.id == deviceId).name;
    try {
      await BluetoothService.connectToDevice(deviceId);
      provider.setConnectedDevice(deviceId);
      provider.addLog("Connected to $deviceName");
      
      // 连接成功后自动停止扫描
      BluetoothService.stopScan();
      provider.stopScan();

      // 更新连接状态
      eegProvider.setConnected(true);
      monitorProvider.setDeviceName(deviceName);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text("Connected"),
              ],
            ),
            content: Text("Successfully connected to $deviceName"),
            actions: [
              TextButton(
                onPressed: () {
                  // 关闭对话框
                  Navigator.of(context).pop();
                  // 直接返回到主页面（monitor页面）
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      provider.addLog("❌ Connection failed to $deviceName");
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600),
                const SizedBox(width: 8),
                const Text("Connection Failed"),
              ],
            ),
            content: Text("Could not connect to $deviceName.\nError: $e"),
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
      appBar: AppBar(
        title: const Text(
          "📡 Bluetooth Connect",
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      bluetooth.isScanning
                          ? Icons.search
                          : bluetooth.connectedDeviceId != null
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                      size: 30,
                      color: bluetooth.isScanning
                          ? Colors.orange
                          : bluetooth.connectedDeviceId != null
                              ? Colors.green
                              : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Connection Status",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bluetooth.isScanning
                                ? "Scanning for devices..."
                                : bluetooth.connectedDeviceId != null
                                    ? "Connected to ${bluetooth.connectedDeviceName}"
                                    : "Disconnected",
                            style: TextStyle(
                              color: bluetooth.isScanning
                                  ? Colors.orange
                                  : bluetooth.connectedDeviceId != null
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Devices List
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Nearby Devices",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: bluetooth.devices.length,
                itemBuilder: (context, index) {
                  final device = bluetooth.devices[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(
                        device.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        device.id,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _connectTo(device.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Connect"),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Logs Section
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  cardTheme: CardTheme(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: const Text(
                    "Connection Logs",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: bluetooth.logs.map((log) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  log.contains("❌") ? Icons.error : Icons.info,
                                  size: 16,
                                  color: log.contains("❌") ? Colors.red : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      color: log.contains("❌") ? Colors.red : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text("Start Scan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                BluetoothService.stopScan();
                context.read<BluetoothProvider>().stopScan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              child: const Text("Stop"),
            ),
          ],
        ),
      ),
    );
  }
}