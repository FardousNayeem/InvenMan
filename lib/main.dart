import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:invenman/app/providers/privacy_provider.dart';
import 'package:invenman/app/providers/theme_provider.dart';
import 'package:invenman/screens/homescreen.dart';
import 'package:invenman/services/database/db_service.dart';
import 'package:invenman/theme/app_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DBHelper.initialize();

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