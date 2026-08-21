import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final jsonFile = File('assets/data/world_cities.json');
  final countriesFile = File('assets/data/world_countries.json');

  group('world_cities.json asset validation', () {
    late List<dynamic> rows;

    setUpAll(() {
      expect(
        jsonFile.existsSync(),
        isTrue,
        reason: 'assets/data/world_cities.json is missing from the project',
      );
      rows = json.decode(jsonFile.readAsStringSync()) as List;
    });

    test('contains a substantial number of cities', () {
      expect(rows.length, greaterThan(20000));
    });

    test('every row has the expected structure and types', () {
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        expect(row, isA<List>(), reason: 'row $i is not a JSON array');
        expect(
          row.length,
          7,
          reason: 'row $i has ${row.length} fields instead of 7',
        );
        expect(row[0], isA<int>(), reason: 'row $i: id must be an int');
        expect(row[1], isA<String>(), reason: 'row $i: name must be a String');
        expect(row[2], isA<String>(),
            reason: 'row $i: arabicName must be a String');
        expect(row[3], isA<String>(),
            reason: 'row $i: countryCode must be a String');
      }
    });

    test('every city has valid coordinates', () {
      final invalid = <String>[];

      for (final row in rows) {
        final name = row[1] as String;
        final lat = (row[4] as num).toDouble();
        final lng = (row[5] as num).toDouble();

        if (lat.isNaN || lat < -90 || lat > 90) {
          invalid.add('$name: latitude out of range ($lat)');
        }
        if (lng.isNaN || lng < -180 || lng > 180) {
          invalid.add('$name: longitude out of range ($lng)');
        }
        if (lat == 0 && lng == 0) {
          invalid.add('$name: null-island placeholder coordinates (0, 0)');
        }
      }

      expect(invalid, isEmpty, reason: 'invalid coordinate entries found');
    });

    test('every city has non-empty name and country code', () {
      final invalid = <String>[];

      for (final row in rows) {
        final id = row[0];
        final name = (row[1] as String).trim();
        final cc = (row[3] as String).trim();

        if (name.isEmpty) invalid.add('$id: empty name');
        if (cc.isEmpty || cc.length != 2) {
          invalid.add('$name: invalid country code "$cc"');
        }
      }

      expect(invalid, isEmpty);
    });

    test('all city ids are unique', () {
      final ids = rows.map((row) => row[0] as int).toSet();
      expect(ids.length, rows.length,
          reason: 'duplicate geonameids found in dataset');
    });

    test('Arab cities are prioritized at the start of the list', () {
      const arabCodes = {
        'SA', 'YE', 'EG', 'AE', 'KW', 'QA', 'BH', 'OM', 'JO', 'LB',
        'SY', 'IQ', 'PS', 'MA', 'DZ', 'TN', 'LY', 'SD', 'MR', 'DJ',
        'KM', 'SO',
      };

      var firstNonArabIndex = -1;
      for (var i = 0; i < rows.length; i++) {
        if (!arabCodes.contains(rows[i][3])) {
          firstNonArabIndex = i;
          break;
        }
      }

      expect(firstNonArabIndex, greaterThan(1000),
          reason: 'expected over 1000 Arab cities sorted first');

      for (var i = 0; i < firstNonArabIndex; i++) {
        expect(arabCodes.contains(rows[i][3]), isTrue,
            reason: 'non-Arab city "${rows[i][1]}" appears before index '
                '$firstNonArabIndex');
      }
    });

    test('known cities exist with sane coordinates', () {
      double? latOf(String name) {
        for (final row in rows) {
          if (row[1] == name) return (row[4] as num).toDouble();
        }
        return null;
      }

      expect(latOf('Makkah'), allOf(greaterThan(21.0), lessThan(22.0)));
      expect(latOf('Riyadh'), allOf(greaterThan(24.0), lessThan(25.5)));
      expect(latOf('Cairo'), allOf(greaterThan(29.0), lessThan(31.0)));
      expect(latOf('Dubai'), allOf(greaterThan(24.5), lessThan(26.0)));
    });
  });

  group('world_countries.json asset validation', () {
    test('is valid and covers Arab countries', () {
      expect(countriesFile.existsSync(), isTrue);

      final countries =
          json.decode(countriesFile.readAsStringSync()) as Map<String, dynamic>;

      expect(countries.length, greaterThan(200));

      for (final cc in ['SA', 'EG', 'AE', 'MA', 'IQ']) {
        expect(
          countries[cc],
          isA<String>(),
          reason: 'missing English name for country code $cc',
        );
      }
    });
  });
}
