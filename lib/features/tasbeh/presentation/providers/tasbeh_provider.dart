import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbehProvider extends ChangeNotifier {
  static const String _kTotalTasbehCountKey = 'total_tasbeh_count';
  static const String _kCurrentSessionTasbehCountKey =
      'current_session_tasbeh_count';
  int _count = 0;
  int get count => _count;
  int _savedCount = 0;
  int get savedCount => _savedCount;

  Future<void> loadCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _savedCount = prefs.getInt(_kTotalTasbehCountKey) ?? 0;
    _count = prefs.getInt(_kCurrentSessionTasbehCountKey) ?? 0;
    notifyListeners();
  }

  Future<void> addCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _count++;
    _savedCount++;
    await prefs.setInt(_kTotalTasbehCountKey, _savedCount);
    await prefs.setInt(_kCurrentSessionTasbehCountKey, _count);
    notifyListeners();
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _count = 0;
    await prefs.setInt(_kCurrentSessionTasbehCountKey, 0);
    notifyListeners();
  }

  Future<void> resetAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _count = 0;
    _savedCount = 0;
    await prefs.setInt(_kCurrentSessionTasbehCountKey, 0);
    await prefs.setInt(_kTotalTasbehCountKey, 0);
    notifyListeners();
  }
}
