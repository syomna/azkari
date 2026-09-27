abstract class QuranRepository {
  Future<void> saveLatestQuranSurahNumber(int surahNumber);
  int? getLatestQuranSurahNumber();
  Future<void> saveQuranPageNumber(int pageNumber);
  int? getSavedQuranPageNumber();
  Future<void> clearSavedPosition();
  Future<void> clearAllSavedQuranValues();
  Future<void> downloadSurah(String url, String savePath);
  Future<String> getSurahPath(int surahNumber);
  Future<bool> isSurahDownloaded(int surahNumber);
  Future<void> saveQuranBookmark(int surahNumber, int pageNumber);
  int? getQuranBookmarkSurah();
  int? getQuranBookmarkPage();
  Future<void> clearQuranBookmark();
}
