import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyProvider with ChangeNotifier {
  static const String _privacyKey = 'hideSensitiveValues';

  bool _hideSensitiveValues = false;

  bool get hideSensitiveValues => _hideSensitiveValues;
  bool get showSensitiveValues => !_hideSensitiveValues;

  PrivacyProvider() {
    _loadPrivacySetting();
  }

  Future<void> toggleSensitiveVisibility() async {
    _hideSensitiveValues = !_hideSensitiveValues;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, _hideSensitiveValues);
  }

  Future<void> _loadPrivacySetting() async {
    final prefs = await SharedPreferences.getInstance();

    _hideSensitiveValues = prefs.getBool(_privacyKey) ?? false;

    notifyListeners();
  }
}