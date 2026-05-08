
abstract class QuranRepository {
  Future<void> saveLatestQuranSurahNumber(int surahNumber);
  int? getLatestQuranSurahNumber();
  Future<void> saveQuranPageNumber(int pageNumber);
  int? getSavedQuranPageNumber();
  // Future<void> saveQuranPosition(QuranPositionEntity position);
  // QuranPositionEntity getSavedPosition(int surahNumber);
  // Future<void> clearSavedPosition(int surahNumber);
  Future<void> clearAllSavedQuranValues();
  Future<void> downloadSurah(String url, String savePath);
  Future<String> getSurahPath(int surahNumber);
Future<bool> isSurahDownloaded(int surahNumber);
}
