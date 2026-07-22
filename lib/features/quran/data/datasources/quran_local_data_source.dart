abstract class QuranLocalDataSource {
  Future<void> saveLatestQuranSurahNumber(int surahNumber);
  int? getLatestQuranSurahNumber();
  int? getSavedQuranPageNumber();
  Future<void> saveQuranPageNumber(int pageNumber);
  Future<void> clearSavedPosition();
  Future<void> clearAllSavedQuranValues();
  Future<String> getSurahPath(int surahNumber);
  Future<bool> isDownloaded(int surahNumber);
}
