import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const CityEaseApp());
}

class CityEaseApp extends StatelessWidget {
  const CityEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CityEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.primaryBackground,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accentColor,
          secondary: AppTheme.accentColorLight,
          surface: AppTheme.cardBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
