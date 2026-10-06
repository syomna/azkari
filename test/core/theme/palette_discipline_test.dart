import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// قاعدة المشروع: كل الألوان معرَّفة في `app_palette.dart` وحده، ولا يُكتب
/// لون حرفي داخل أي شاشة أو ويدجت. هذا الاختبار يمشي على `lib/` ويمنع عودة
/// الألوان إلى أماكنها.
void main() {
  test('لا توجد ألوان حرفية خارج app_palette.dart', () {
    final libDir = Directory('${Directory.current.path}/lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ غير موجود');

    final literal = RegExp(r'Color\(\s*0x[0-9A-Fa-f]+');
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('app_palette.dart')) continue;

      final lines = entity.path.split(Platform.pathSeparator);
      final relative = lines.sublist(lines.indexOf('lib') + 1).join('/');
      final source = entity.readAsStringSync();
      final linesWithColor = source
          .split('\n')
          .asMap()
          .entries
          .where((entry) => literal.hasMatch(entry.value))
          .map((entry) => '$relative:${entry.key + 1}');

      offenders.addAll(linesWithColor);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'انقل هذه الألوان إلى AppPalette:\n${offenders.join('\n')}',
    );
  });

  test('لا يوجد Colors.red/redAccent خارج app_palette.dart', () {
    final libDir = Directory('${Directory.current.path}/lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ غير موجود');

    final literal = RegExp(r'Colors\.(red|redAccent)\b');
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('app_palette.dart')) continue;

      final lines = entity.path.split(Platform.pathSeparator);
      final relative = lines.sublist(lines.indexOf('lib') + 1).join('/');
      final source = entity.readAsStringSync();
      final linesWithColor = source
          .split('\n')
          .asMap()
          .entries
          .where((entry) => literal.hasMatch(entry.value))
          .map((entry) => '$relative:${entry.key + 1}');

      offenders.addAll(linesWithColor);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'ألوان الخطأ والحذف الصريحة عبر AppPalette.errorColor:\n'
          '${offenders.join('\n')}',
    );
  });
}
