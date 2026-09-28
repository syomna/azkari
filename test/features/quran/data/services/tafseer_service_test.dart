import 'package:azkar_app/features/quran/data/services/tafseer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TafseerService.edition', () {
    test('uses the valid alquran.cloud tafsir identifier', () {
      // ar.al-muyassar كان معرّفاً غير موجود فيرجع الـ API نص الآية نفسها
      // بدل التفسير، فيظهر التفسير مساوياً للآية. المعرّف الصحيح هو
      // ar.muyassar (تفسير مجمع الملك فهد) من قائمة editions في الـ API.
      expect(TafseerService().edition, 'ar.muyassar');
    });
  });

  group('TafseerService.cleanTafseerText', () {
    test('removes HTML tags', () {
      const raw = 'قوله تعالى <b>اهْدِنَا</b> أي دُلَّنا.';
      expect(TafseerService.cleanTafseerText(raw),
          'قوله تعالى اهْدِنَا أي دُلَّنا.');
    });

    test('removes bracket ayah-number markers (arabic/a western digits)', () {
      const raw = ' وهذا معنى الآية (١) ثم يأتي البيان (2) بعده.';
      expect(TafseerService.cleanTafseerText(raw),
          'وهذا معنى الآية ثم يأتي البيان بعده.');
    });

    test('collapses repeated whitespace', () {
      const raw = '  نزَلت   في   الصلاة   ';
      expect(TafseerService.cleanTafseerText(raw), 'نزَلت في الصلاة');
    });

    test('decodes basic HTML entities', () {
      const raw = 'قال &quot;الله&quot; ثم &#39;سبحانه&#39; و &amp; بعدهم';
      expect(
        TafseerService.cleanTafseerText(raw),
        "قال \"الله\" ثم 'سبحانه' و & بعدهم",
      );
    });

    test('keeps plain text unchanged', () {
      const raw = 'التفسير الميسر يختصر المعنى بلغة سهلة.';
      expect(TafseerService.cleanTafseerText(raw), raw);
    });
  });
}
