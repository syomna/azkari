import 'dart:convert';

import 'package:azkar_app/models/azkar_model.dart';
import 'package:azkar_app/models/names_of_allah_model.dart';
import 'package:azkar_app/models/surah_model.dart';
import 'package:flutter/services.dart';

class DataProvider {
  Future<List<AzkarModel>> loadAzkar() async {
    try {
      final jsonString = await rootBundle.loadString('assets/db/azkar.json');
      List<dynamic> jsonData = json.decode(jsonString);
      List<AzkarModel> azkarList =
          jsonData.map((json) => AzkarModel.fromJson(json)).toList();
      return azkarList;
    } catch (e) {
      return [];
    }
  }

  Future<List<NamesOfAllahModel>> loadNamesOfAllah() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/db/names_of_allah.json');
      List<dynamic> jsonData = json.decode(jsonString);
      List<NamesOfAllahModel> namesOfAllah =
          jsonData.map((json) => NamesOfAllahModel.fromJson(json)).toList();
      return namesOfAllah;
    } catch (e) {
      return [];
    }
  }

  Future<List<SurahModel>> loadSurah() async {
    try {
      final jsonString = await rootBundle.loadString('assets/db/surah.json');
      List<dynamic> jsonData = json.decode(jsonString);
      List<SurahModel> surah =
          jsonData.map((json) => SurahModel.fromJson(json)).toList();
      return surah;
    } catch (e) {
      return [];
    }
  }
}
