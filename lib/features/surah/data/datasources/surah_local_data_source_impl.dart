import 'dart:convert';

import 'package:azkar_app/features/surah/data/models/surah_model.dart';
import 'package:azkar_app/features/surah/data/datasources/surah_local_data_source.dart';
import 'package:flutter/services.dart';

class SurahLocalDataSourceImpl extends SurahLocalDataSource {
  @override
  Future<List<SurahModel>> getSurah() async {
    final jsonString = await rootBundle.loadString('assets/db/surah.json');
    List<dynamic> jsonData = json.decode(jsonString);
    List<SurahModel> surah =
        jsonData.map((json) => SurahModel.fromJson(json)).toList();
    return surah;
  }
}
