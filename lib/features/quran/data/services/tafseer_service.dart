import 'package:dio/dio.dart';

/// نتيجة تفسير آية واحدة.
class TafseerEntry {
  final int surahNumber;
  final int verseNumber;
  final String edition;
  final String text;

  const TafseerEntry({
    required this.surahNumber,
    required this.verseNumber,
    required this.edition,
    required this.text,
  });
}

/// خدمة التفسير: تجلب تفسير آية واحدة عند الطلب (تحميل كسول بدل حزم
/// البيانات الضخمة) من أرشيف القرآن المجاني، مع تخزين مؤقت في الذاكرة.
class TafseerService {
  TafseerService({Dio? dio, this.edition = 'ar.al-muyassar'})
      : _dio = dio ?? Dio();

  final Dio _dio;
  final String edition;

  /// تهدف لتجنب نفس الشبكة كلما فتح المستخدم نفس الآية.
  final Map<String, String> _cache = {};

  /// ينظف النص الخام من وسوم HTML وعلامات الترقيم الزائدة.
  static String cleanTafseerText(String raw) {
    String text = raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');
    // الأرقام بين قوسين دائرية: (١) (٢) ...
    text = text.replaceAll(RegExp(r'\(\s*[٠-٩0-9]+\s*\)'), '');
    text = text.replaceAll(RegExp(r'(^|\s)\d+[\.\s]'), '\$1');
    return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  /// يجلب تفسير الآية، مع تدوير التخزين المؤقت عند النجاح ورمي خطأ عند الفشل.
  Future<TafseerEntry> fetchAyah(int surahNumber, int verseNumber) async {
    final key = '$edition:$surahNumber:$verseNumber';
    final cached = _cache[key];
    if (cached != null) {
      return TafseerEntry(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        edition: edition,
        text: cached,
      );
    }

    final response = await _dio
        .get<Map<String, dynamic>>(
          'https://api.alquran.cloud/v1/ayah/$surahNumber:$verseNumber/$edition',
        )
        .timeout(const Duration(seconds: 15));

    final data = response.data?['data'];
    final raw = data is Map<String, dynamic> ? data['text'] : null;
    if (raw is! String || raw.trim().isEmpty) {
      throw Exception('تعذر تحميل التفسير لهذه الآية');
    }

    final text = cleanTafseerText(raw);
    _cache[key] = text;
    return TafseerEntry(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      edition: edition,
      text: text,
    );
  }
}
