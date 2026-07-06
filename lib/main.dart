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
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.primaryBackground,
        canvasColor: AppTheme.primaryBackground,
        fontFamily: 'Inter',
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Inter',
          bodyColor: AppTheme.textSecondary,
          displayColor: AppTheme.textPrimary,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accentColor,
          secondary: AppTheme.accentColorLight,
          surface: AppTheme.cardBackground,
          onSurface: AppTheme.textSecondary,
          onPrimary: Colors.white,
          onSecondary: AppTheme.textPrimary,
          tertiary: AppTheme.successColor,
          error: AppTheme.errorColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
        ),
        cardTheme: CardThemeData(
          color: AppTheme.cardBackground.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            ),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accentColorLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppTheme.cardBackground.withValues(alpha: 0.72),
          selectedColor: AppTheme.accentColor.withValues(alpha: 0.22),
          side: BorderSide(color: AppTheme.borderTranslucent),
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          secondaryLabelStyle: const TextStyle(color: AppTheme.textPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.cardBackground.withValues(alpha: 0.7),
          hintStyle: const TextStyle(color: AppTheme.textMuted),
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.borderTranslucent),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.accentColorLight),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x33FFFFFF),
          thickness: 0.6,
        ),
        iconTheme: const IconThemeData(color: AppTheme.textSecondary),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
