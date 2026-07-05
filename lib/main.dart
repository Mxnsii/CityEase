import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';

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
        scaffoldBackgroundColor: const Color(0xFF090B19),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6F5CFF),
          secondary: Color(0xFF8C88FF),
          surface: Color(0xFF11162D),
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
