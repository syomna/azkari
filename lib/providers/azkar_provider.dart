import 'package:azkar_app/models/azkar_model.dart';
import 'package:azkar_app/models/names_of_allah_model.dart';
import 'package:azkar_app/models/surah_model.dart';
import 'package:azkar_app/utils/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzkarProvider extends ChangeNotifier {
  List<AzkarModel> _allAzkar = [];
  List<NamesOfAllahModel> _namesOfAllah = [];
  List<SurahModel> _surah = [];
  List<AzkarModel> get allAzkar => _allAzkar;
  List<NamesOfAllahModel> get namesOfAllah => _namesOfAllah;
  List<SurahModel> get surah => _surah;
  int _count = 0;
  int get count => _count;
  int _savedCount = 0;
  int get savedCount => _savedCount;

  loadAllData() async {
    _allAzkar = await DataProvider().loadAzkar();
    _namesOfAllah = await DataProvider().loadNamesOfAllah();
    _surah = await DataProvider().loadSurah();
    notifyListeners();
  }

  loadCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _savedCount = prefs.getInt('count') ?? 0;
    _count = prefs.getInt('count_present') ?? 0;
    notifyListeners();
  }

  addCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _count++;
    _savedCount++;
    await prefs.setInt('count', _savedCount);
    await prefs.setInt('count_present', _count);
    notifyListeners();
  }

  reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _count = 0;
    await prefs.setInt('count_present', 0);
    notifyListeners();
  }
}
