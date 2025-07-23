import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbehProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;

  TasbehProvider({required this.sharedPreferences});

  static const String _kTotalTasbehCountKey = 'total_tasbeh_count';
  static const String _kCurrentSessionTasbehCountKey =
      'current_session_tasbeh_count';
  int _count = 0;
  int get count => _count;
  int _savedCount = 0;
  int get savedCount => _savedCount;

  Future<void> loadCount() async {
    _savedCount = sharedPreferences.getInt(_kTotalTasbehCountKey) ?? 0;
    _count = sharedPreferences.getInt(_kCurrentSessionTasbehCountKey) ?? 0;
    // notifyListeners();
  }

  Future<void> addCount() async {
    _count++;
    _savedCount++;
    await sharedPreferences.setInt(_kTotalTasbehCountKey, _savedCount);
    await sharedPreferences.setInt(_kCurrentSessionTasbehCountKey, _count);
    notifyListeners();
  }

  Future<void> reset() async {
    _count = 0;
    await sharedPreferences.setInt(_kCurrentSessionTasbehCountKey, 0);
    notifyListeners();
  }

  Future<void> resetAll() async {
    _count = 0;
    _savedCount = 0;
    await sharedPreferences.setInt(_kCurrentSessionTasbehCountKey, 0);
    await sharedPreferences.setInt(_kTotalTasbehCountKey, 0);
    notifyListeners();
  }
}
