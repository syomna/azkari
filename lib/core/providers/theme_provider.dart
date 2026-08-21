import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  ThemeProvider({required this.prefs});
  static const String _themeModeKey = 'themeMode';
  static const String _textScaleFactorKey = 'textScaleFactor';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  double _textScaleFactor = 1.0;
  double get textScaleFactor => _textScaleFactor;

  bool get isLight {
    if (_themeMode == ThemeMode.light) return true;
    if (_themeMode == ThemeMode.dark) return false;
    return PlatformDispatcher.instance.platformBrightness != Brightness.dark;
  }

  Future<void> loadTheme() async {
    final raw = prefs.getString(_themeModeKey);
    _themeMode = _themeModeFromString(raw);
    _textScaleFactor = prefs.getDouble(_textScaleFactorKey) ?? 1.0;
  }

  Future<void> _savePreferences() async {
    await prefs.setString(_themeModeKey, _themeModeString(_themeMode));
    await prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void cycleThemeMode() {
    final next =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(next);
  }

  void setTextScaleFactor(double newFactor) {
    final clampedFactor = newFactor.clamp(0.8, 1.5);

    if (_textScaleFactor != clampedFactor) {
      _textScaleFactor = clampedFactor;
      _savePreferences();
      notifyListeners();
    }
  }

  static ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'auto',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
  }
}
