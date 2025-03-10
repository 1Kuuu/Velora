import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF8B1539),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF8B1539),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF8B1539);
        }
        return null;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF8B1539).withOpacity(0.5);
        }
        return null;
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black),
    ),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF8B1539),
      secondary: const Color(0xFF8B1539),
      surface: Colors.white,
      background: Colors.grey[100]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF4A3B7C),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4A3B7C),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF4A3B7C),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF4A3B7C);
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF4A3B7C).withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
      titleMedium: TextStyle(color: Colors.white),
    ),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF4A3B7C),
      secondary: const Color(0xFF4A3B7C),
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
      onBackground: Colors.white70,
    ),
    dialogBackgroundColor: const Color(0xFF1E1E1E),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E1E),
    ),
    dividerColor: Colors.white24,
  );
}
