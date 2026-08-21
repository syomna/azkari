import 'package:azkar_app/features/surah/data/models/surah_model.dart';

abstract class SurahLocalDataSource {
  Future<List<SurahModel>> getSurah();
}
