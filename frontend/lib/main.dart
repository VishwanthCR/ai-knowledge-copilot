import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const AIKnowledgeCopilotApp());
}

class AIKnowledgeCopilotApp extends StatefulWidget {
  const AIKnowledgeCopilotApp({super.key});

  @override
  State<AIKnowledgeCopilotApp> createState() =>
      _AIKnowledgeCopilotAppState();
}

class _AIKnowledgeCopilotAppState
    extends State<AIKnowledgeCopilotApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D5DFB),
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFF8F8FB),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F8FB),
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F3F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B7CFF),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF101014),
        surfaceContainerLowest: const Color(0xFF0D0D11),
        surfaceContainerLow: const Color(0xFF141419),
        surfaceContainer: const Color(0xFF19191F),
        surfaceContainerHigh: const Color(0xFF202027),
        surfaceContainerHighest: const Color(0xFF292930),
      ),
      scaffoldBackgroundColor: const Color(0xFF101014),
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF202027),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'AI Knowledge Copilot',

      theme: _lightTheme(),

      darkTheme: _darkTheme(),

      themeMode: _themeMode,

      home: HomeScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}