import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // Full theme definitions keep the app bar, cards, input fields, navigation
  // bar, and controls in sync when the user changes appearance.
  ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: Color(0xFF123B7A),
      onPrimary: Colors.white,
      secondary: Color(0xFFFFC107),
      onSecondary: Color(0xFF1E1B16),
      surface: Color(0xFFFFF9FF),
      onSurface: Color(0xFF1C1B20),
      outline: Color(0xFF79747E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFF9FF),
        foregroundColor: Color(0xFF1C1B20),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFF9FF),
        selectedItemColor: Color(0xFF123B7A),
        unselectedItemColor: Color(0xFF625B71),
      ),
    );
  }

  ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: Color(0xFFAFC6FF),
      onPrimary: Color(0xFF002E68),
      secondary: Color(0xFFFFD95A),
      onSecondary: Color(0xFF3D2F00),
      surface: Color(0xFF121218),
      onSurface: Color(0xFFE5E1E9),
      outline: Color(0xFF938F99),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1D1B20),
        foregroundColor: Color(0xFFE5E1E9),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1D1B20),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF211F26),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1D1B20),
        selectedItemColor: Color(0xFFAFC6FF),
        unselectedItemColor: Color(0xFFCAC4D0),
      ),
    );
  }
}
