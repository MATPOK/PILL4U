import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  // Singleton - wspólne ustawienia dostępne w całej aplikacji.
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  ThemeMode themeMode = ThemeMode.system;
  double textScale = 1.0;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Wczytywanie motywu
    final themeStr = prefs.getString('theme_mode') ?? 'system';
    if (themeStr == 'light') {
      themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }

    // Wczytywanie czcionki
    textScale = prefs.getDouble('text_scale') ?? 1.0;

    notifyListeners(); // odświeża całą aplikację
  }

  Future<void> updateThemeMode(ThemeMode newMode) async {
    themeMode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newMode.name);
  }

  Future<void> updateTextScale(double newScale) async {
    textScale = newScale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale', newScale);
  }
}