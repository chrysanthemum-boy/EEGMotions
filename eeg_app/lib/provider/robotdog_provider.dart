import 'package:flutter/material.dart';

class RobotDogProvider extends ChangeNotifier {
  bool _enabled = false;
  String _mode = 'Freeze';

  bool get enabled => _enabled;
  String get mode => _mode;

  void setEnabled(bool val) {
    _enabled = val;
    notifyListeners();
  }

  void setMode(String newMode) {
    _mode = newMode;
    notifyListeners();
  }
}
