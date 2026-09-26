import 'dart:convert';

import 'package:azkar_app/features/names_of_allah/data/datasources/names_of_allah_local_data_source_impl.dart';
import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';
import 'package:azkar_app/features/surah/data/datasources/surah_local_data_source_impl.dart';
import 'package:azkar_app/features/surah/data/models/surah_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _expectedNamesCount = 100;
const _expectedSurahCount = 25;

Future<List<Map<String, dynamic>>> _readObjectList(String path) async {
  final decoded = jsonDecode(await rootBundle.loadString(path));
  expect(decoded, isA<List<dynamic>>());
  return (decoded as List<dynamic>)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('names of Allah asset', () {
    test('contains the complete expected number of records', () async {
      final records = await _readObjectList('assets/db/names_of_allah.json');

      expect(records, hasLength(_expectedNamesCount));
    });

    test('contains only populated required fields', () async {
      final records = await _readObjectList('assets/db/names_of_allah.json');

      for (final record in records) {
        expect(record['id'], isA<int>());
        expect(record['name'], isA<String>());
        expect(record['text'], isA<String>());
        expect((record['name'] as String).trim(), isNotEmpty);
        expect((record['text'] as String).trim(), isNotEmpty);
      }
    });

    test('uses unique IDs covering the complete expected range', () async {
      final records = await _readObjectList('assets/db/names_of_allah.json');
      final ids =
          records.map((record) => record['id']).whereType<int>().toList();
      final expectedIds = List<int>.generate(
        _expectedNamesCount,
        (index) => index + 1,
      );
      final seenIds = <int>{};
      final duplicateIds = <int>{};
      for (final id in ids) {
        if (!seenIds.add(id)) {
          duplicateIds.add(id);
        }
      }
      final missingIds = expectedIds.where((id) => !ids.contains(id)).toList();

      expect(duplicateIds, isEmpty);
      expect(missingIds, isEmpty);
      expect(ids.toSet(), hasLength(_expectedNamesCount));
      expect(ids.toSet(), expectedIds.toSet());
    });

    test('loads and maps every record through the production data source',
        () async {
      final result = await NamesOfAllahLocalDataSourceImpl().getNamesOfAllah();
      final models = result.fold(
        (_) => <NamesOfAllahModel>[],
        (items) => items,
      );

      expect(models, hasLength(_expectedNamesCount));
      expect(models.every((model) => model.id > 0), isTrue);
      expect(models.every((model) => model.name.trim().isNotEmpty), isTrue);
      expect(models.every((model) => model.text.trim().isNotEmpty), isTrue);
    });
  });

  group('surah asset', () {
    test('contains the complete expected number of records', () async {
      final records = await _readObjectList('assets/db/surah.json');

      expect(records, hasLength(_expectedSurahCount));
    });

    test('contains only populated required fields', () async {
      final records = await _readObjectList('assets/db/surah.json');

      for (final record in records) {
        expect(record['name'], isA<String>());
        expect(record['surah'], isA<String>());
        expect((record['name'] as String).trim(), isNotEmpty);
        expect((record['surah'] as String).trim(), isNotEmpty);
      }
    });

    test('uses unique surah names', () async {
      final records = await _readObjectList('assets/db/surah.json');
      final names = records.map((record) => record['name']).whereType<String>();

      expect(names.toSet(), hasLength(records.length));
    });

    test('loads and maps every record through the production data source',
        () async {
      final result = await SurahLocalDataSourceImpl().getSurah();
      final models = result.fold(
        (_) => <SurahModel>[],
        (items) => items,
      );

      expect(models, hasLength(_expectedSurahCount));
      expect(models.every((model) => model.name.trim().isNotEmpty), isTrue);
      expect(models.every((model) => model.surah.trim().isNotEmpty), isTrue);
    });
  });
}
