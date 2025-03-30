import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/monitor_page.dart';
// import 'pages/test_page.dart';
import 'pages/bluetooth_connect_page.dart';
import 'pages/eeg_display_page.dart';
import 'provider/eeg_provider.dart';
import 'provider/bluetooth_provider.dart';
import 'provider/monitor_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EEGProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => MonitorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EEG App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _pages = [
    // TestPage(),
    MonitorPage(),
    EEGDisplayPage(),
    BluetoothConnectPage(),
  ];

  final _titles = [
    // "🧪 Single Test",
    "🧠 Real-time Monitor",
    "📈 EEG Chart",
    "📡 Bluetooth Connect",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.flash_on),
          //   label: "Test",
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: "Monitor",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: "Display",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: "Connect",
          ),
        ],
      ),
    );
  }
}
