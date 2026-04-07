import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invenman/db.dart';
import 'package:invenman/screens/homescreen.dart';
import 'package:invenman/theme/app_ui.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDark';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.db;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PrivacyProvider()),
      ],
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InvenMan',
      themeMode: themeProvider.themeMode,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}