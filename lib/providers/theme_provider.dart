import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool isLight = true;

  loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    isLight = prefs.getBool('isLight') ?? true;
    notifyListeners();
  }

  void toggleTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    isLight = !isLight;
    await prefs.setBool('isLight', isLight);
    await loadTheme();
    notifyListeners();
  }
}
