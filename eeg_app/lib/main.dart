import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/monitor_page.dart';
import 'pages/eeg_display_page.dart';
import 'provider/eeg_provider.dart';
import 'provider/bluetooth_provider.dart';
import 'provider/monitor_provider.dart';
import 'pages/setting_page.dart';
import 'provider/robotdog_provider.dart';
import 'pages/robot_dog_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final eegProvider = EEGProvider();
  final bluetoothProvider = BluetoothProvider();
  final monitorProvider = MonitorProvider();
  final robotDogProvider = RobotDogProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: eegProvider),
        ChangeNotifierProvider.value(value: bluetoothProvider),
        ChangeNotifierProvider.value(value: monitorProvider),
        ChangeNotifierProvider.value(value: robotDogProvider),
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
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const MonitorPage(),
      const EEGDisplayPage(),
      const RobotDogPage(),
      const SettingsPage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart),
              label: "Monitor",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.data_usage),
              label: "Display",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: "Robot Dog",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}
