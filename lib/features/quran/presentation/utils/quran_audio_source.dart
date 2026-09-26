/// Self-contained Quran audio metadata and URLs so the audio feature works
/// without depending on the `quran` package (which is still used by the reader
/// for the mushaf text). Keeps the previous CDN/reciter exactly unchanged, so
/// existing downloads and URLs keep working.
class QuranAudioSource {
  QuranAudioSource._();

  /// CDN that hosts per-surah recitations.
  static const String cdnBase = 'https://cdn.islamic.network/quran/audio-surah';

  /// Default reciter path on the CDN (Mishary Rashid Alafasy).
  static const String defaultReciter = 'ar.alafasy';

  /// Builds the mp3 URL for [surahNumber] (1-based, 1..114).
  static String urlForSurah(
    int surahNumber, {
    String reciter = defaultReciter,
    int bitrate = 128,
  }) {
    return '$cdnBase/$bitrate/$reciter/$surahNumber.mp3';
  }

  /// Arabic surah names, 1-based (index 0 = الفاتحة … index 113 = الناس).
  static const List<String> surahArabicNames = [
    'الفاتحة',
    'البقرة',
    'آل عمران',
    'النساء',
    'المائدة',
    'الأنعام',
    'الأعراف',
    'الأنفال',
    'التوبة',
    'يونس',
    'هود',
    'يوسف',
    'الرعد',
    'ابراهيم',
    'الحجر',
    'النحل',
    'الإسراء',
    'الكهف',
    'مريم',
    'طه',
    'الأنبياء',
    'الحج',
    'المؤمنون',
    'النور',
    'الفرقان',
    'الشعراء',
    'النمل',
    'القصص',
    'العنكبوت',
    'الروم',
    'لقمان',
    'السجدة',
    'الأحزاب',
    'سبإ',
    'فاطر',
    'يس',
    'الصافات',
    'ص',
    'الزمر',
    'غافر',
    'فصلت',
    'الشورى',
    'الزخرف',
    'الدخان',
    'الجاثية',
    'الأحقاف',
    'محمد',
    'الفتح',
    'الحجرات',
    'ق',
    'الذاريات',
    'الطور',
    'النجم',
    'القمر',
    'الرحمن',
    'الواقعة',
    'الحديد',
    'المجادلة',
    'الحشر',
    'الممتحنة',
    'الصف',
    'الجمعة',
    'المنافقون',
    'التغابن',
    'الطلاق',
    'التحريم',
    'الملك',
    'القلم',
    'الحاقة',
    'المعارج',
    'نوح',
    'الجن',
    'المزمل',
    'المدثر',
    'القيامة',
    'الانسان',
    'المرسلات',
    'النبأ',
    'النازعات',
    'عبس',
    'التكوير',
    'الإنفطار',
    'المطففين',
    'الإنشقاق',
    'البروج',
    'الطارق',
    'الأعلى',
    'الغاشية',
    'الفجر',
    'البلد',
    'الشمس',
    'الليل',
    'الضحى',
    'الشرح',
    'التين',
    'العلق',
    'القدر',
    'البينة',
    'الزلزلة',
    'العاديات',
    'القارعة',
    'التكاثر',
    'العصر',
    'الهمزة',
    'الفيل',
    'قريش',
    'الماعون',
    'الكوثر',
    'الكافرون',
    'النصر',
    'المسد',
    'الإخلاص',
    'الفلق',
    'الناس',
  ];

  /// Arabic name for [surahNumber] (1-based). Unknown numbers fall back to a
  /// generic label so a corrupt index never crashes the audio card.
  static String surahName(int surahNumber) {
    if (surahNumber < 1 || surahNumber > surahArabicNames.length) {
      return 'سورة';
    }
    return surahArabicNames[surahNumber - 1];
  }
}
