import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:flutter_test/flutter_test.dart';

ZekrEntity _zekr(String category) => ZekrEntity(
      category: category,
      zekr: 'نص',
      count: '1',
      description: '',
      reference: '',
    );

void main() {
  group('isDuaCategory', () {
    test('يقبل صيغ الدعاء الثلاث', () {
      expect(isDuaCategory('دعاء الكرب'), isTrue);
      expect(isDuaCategory('الدعاء للمريض في عيادته'), isTrue);
      expect(isDuaCategory('أدعية النجاح والتوفيق'), isTrue);
      expect(isDuaCategory('من أدعية الاستسقاء'), isTrue);
    });

    test('يرفض الأذكار والمواضيع الأخرى', () {
      expect(isDuaCategory('أذكار الصباح'), isFalse);
      expect(isDuaCategory('أذكار المساء'), isFalse);
      expect(isDuaCategory('أذكار النوم'), isFalse);
      expect(isDuaCategory('أذكار الآذان'), isFalse);
      expect(isDuaCategory('التسبيح، التحميد، التهليل، التكبير'), isFalse);
    });

    test('يتجاهل المسافات الطرفية', () {
      expect(isDuaCategory('  دعاء السفر  '), isTrue);
    });
  });

  group('duaCategoriesFrom', () {
    test('يرجع موضوعات الأدعية فقط، مرة واحدة، مرتبة', () {
      final List<String> result = duaCategoriesFrom([
        _zekr('أذكار الصباح'),
        _zekr('دعاء الكرب'),
        _zekr('دعاء السفر'),
        _zekr('دعاء الكرب'),
        _zekr('أدعية طلب العلم'),
      ]);

      expect(result, ['أدعية طلب العلم', 'دعاء السفر', 'دعاء الكرب']);
    });

    test('قائمة فارغة حين لا توجد أدعية', () {
      expect(duaCategoriesFrom([_zekr('أذكار الصباح')]), isEmpty);
      expect(duaCategoriesFrom(const []), isEmpty);
    });
  });
}
