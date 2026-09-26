import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranLocalDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = QuranLocalDataSourceImpl(sharedPreferences: prefs);
  });

  test('bookmark roundtrip persists surah and page', () async {
    await dataSource.saveQuranBookmark(114, 604);

    expect(dataSource.getQuranBookmarkSurah(), 114);
    expect(dataSource.getQuranBookmarkPage(), 604);
  });

  test('clearQuranBookmark removes both stored values', () async {
    await dataSource.saveQuranBookmark(2, 44);

    await dataSource.clearQuranBookmark();

    expect(dataSource.getQuranBookmarkSurah(), isNull);
    expect(dataSource.getQuranBookmarkPage(), isNull);
  });

  test('bookmark is independent from auto-resume position', () async {
    await dataSource.saveQuranBookmark(18, 300);

    // flipping pages re-saves the auto-resume position...
    await dataSource.saveLatestQuranSurahNumber(2);
    await dataSource.saveQuranPageNumber(5);

    // ...which must not clobber the explicit bookmark
    expect(dataSource.getQuranBookmarkSurah(), 18);
    expect(dataSource.getQuranBookmarkPage(), 300);
  });
}