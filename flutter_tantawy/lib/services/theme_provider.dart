import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app theme mode (light/dark) with persistence.
class ThemeModeProvider extends ChangeNotifier {
  bool _isDark = false;
  static const String _kPrefsKey = 'app_is_dark_mode';

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeModeProvider() {
    _loadSavedTheme();
  }

  void _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_kPrefsKey) ?? false;
      notifyListeners();
    } catch (e) {
      _isDark = false;
    }
  }

  void toggleTheme() {
    _isDark = !_isDark;
    _saveTheme();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    if (_isDark != isDark) {
      _isDark = isDark;
      _saveTheme();
      notifyListeners();
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefsKey, _isDark);
    } catch (e) {
      // Ignore save errors
    }
  }
}
