// lib/core/presentation/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  ThemeProvider({required this.prefs}) {
    _themeMode = _readMode();
    _textScaleFactor = (prefs.getDouble(_textScaleFactorKey) ?? 1.0)
        .clamp(0.8, 1.5)
        .toDouble();
  }

  static const String _themeModeKey = 'themeMode';
  static const String _isLightKey = 'isLight';
  static const String _textScaleFactorKey = 'textScaleFactor';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  double _textScaleFactor = 1.0;
  double get textScaleFactor => _textScaleFactor;

  /// Reads the stored theme mode, migrating the legacy boolean `isLight`
  /// preference for existing users. Defaults to [ThemeMode.system] (auto).
  ThemeMode _readMode() {
    final stored = prefs.getString(_themeModeKey);
    if (stored != null) return _modeFromString(stored);
    final legacy = prefs.getBool(_isLightKey);
    if (legacy == null) return ThemeMode.system;
    return legacy ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> loadTheme() async {
    _themeMode = _readMode();
    _textScaleFactor = (prefs.getDouble(_textScaleFactorKey) ?? 1.0)
        .clamp(0.8, 1.5)
        .toDouble();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    await prefs.setString(_themeModeKey, _modeToString(_themeMode));
    await prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  /// Quick toggle used from the home header: flips between light/dark. When
  /// currently on auto, it goes dark (until the user picks from settings).
  void toggleTheme() {
    setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setTextScaleFactor(double newFactor) {
    final clampedFactor = newFactor.clamp(0.8, 1.5);

    if (_textScaleFactor != clampedFactor) {
      _textScaleFactor = clampedFactor;
      _savePreferences();
      notifyListeners();
    }
  }

  static ThemeMode _modeFromString(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _modeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
