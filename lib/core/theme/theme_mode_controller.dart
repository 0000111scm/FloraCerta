import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController._() : super(ThemeMode.system);

  static const _key = 'app_theme_mode';
  static final ThemeModeController instance = ThemeModeController._();

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_key);
    value = _themeModeFromRaw(rawValue);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (value == mode) {
      return;
    }
    value = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, _rawFromThemeMode(mode));
  }

  ThemeMode _themeModeFromRaw(String? rawValue) {
    switch (rawValue) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _rawFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
