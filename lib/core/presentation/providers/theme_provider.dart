// lib/core/presentation/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _isLightKey = 'isLight';
  static const String _textScaleFactorKey = 'textScaleFactor';

  bool _isLight = true;
  bool get isLight => _isLight;

  double _textScaleFactor = 1.0;
  double get textScaleFactor => _textScaleFactor;

  Future<void> loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLight = prefs.getBool(_isLightKey) ?? true;
    _textScaleFactor = prefs.getDouble(_textScaleFactorKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLightKey, _isLight);
    await prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
  }

  void toggleTheme() {
    _isLight = !_isLight;
    _savePreferences();
    notifyListeners();
  }

  void setTextScaleFactor(double newFactor) {
    final clampedFactor = newFactor.clamp(0.8, 1.5);

    if (_textScaleFactor != clampedFactor) {
      _textScaleFactor = clampedFactor;
      _savePreferences();
      notifyListeners();
    }
  }
}
