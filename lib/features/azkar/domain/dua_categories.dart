import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';

/// كلمتان تصفان أي موضوع في قاعدة البيانات بأنه دعاء. البيانات لا تحوي
/// تصنيفاً موحّداً للأدعية، بل كل دعاء موضوع مستقل باسمه ("دعاء الكرب"،
/// "أدعية النجاح والتوفيق"، "الدعاء للمريض في عيادته"...)، فالتعرّف على
/// الأدعية يعتمد على الاسم لا على حقل في النموذج.
///
/// ملاحظة عن المطابقة: "الدعاء" تحتوي على "دعاء" داخلها، أما "أدعية" و"دعية"
/// فتحتاج كلمة أخرى، ولذلك نبحث في الصيغ الثلاث معاً.
const List<String> _duaMarkers = ['دعاء', 'دعية', 'دعاءً'];

/// هل [category] موضوع دعاء؟
bool isDuaCategory(String category) {
  final String normalized = category.trim();
  return _duaMarkers.any(normalized.contains);
}

/// أي مكتبة ينتمي إليها موضوع: مكتبة الأذكار أم مكتبة الأدعية. الفصل بينهما
/// بالاسم لا بحقل في النموذج، فيشمل الموضوعات التي يضيفها المستخدم ما دام
/// عنوانه يميّزه.
enum AzkarLibrary { azkar, dua }

/// المكتبة التي ينتمي إليها [category].
AzkarLibrary libraryOf(String category) =>
    isDuaCategory(category) ? AzkarLibrary.dua : AzkarLibrary.azkar;

/// قائمة موضوعات الأدعية من [azkar]، مرتبة أبجدياً ومن غير تكرار. الترتيب
/// أبجدي لأن الأذكار تُرتَّب في صفحة الأدعية حسب اسم الموضوع لا بترتيب
/// قاعدة البيانات.
List<String> duaCategoriesFrom(List<ZekrEntity> azkar) {
  final Set<String> categories = azkar
      .map((ZekrEntity item) => item.category)
      .where(isDuaCategory)
      .toSet();

  final List<String> sorted = categories.toList()
    ..sort((String a, String b) => a.compareTo(b));
  return sorted;
}
