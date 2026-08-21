import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ThemeProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    provider = ThemeProvider(prefs: prefs);
  });

  group('ThemeProvider', () {
    test('initial state is system theme with default scale', () {
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.textScaleFactor, 1.0);
    });

    test('loadTheme reads from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', 'dark');
      await prefs.setDouble('textScaleFactor', 1.3);

      await provider.loadTheme();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.textScaleFactor, 1.3);
    });

    test('loadTheme applies defaults when prefs are empty', () async {
      await provider.loadTheme();
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.textScaleFactor, 1.0);
    });

    test('setThemeMode updates and persists', () async {
      provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'dark');
    });

    test('setThemeMode notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setThemeMode(ThemeMode.dark);
      expect(notifyCount, 1);
    });

    test('setThemeMode does not notify for same value', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setThemeMode(ThemeMode.system);
      expect(notifyCount, 0);
    });

    test('cycleThemeMode toggles light ↔ dark', () {
      provider.setThemeMode(ThemeMode.light);
      provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.dark);

      provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.light);
    });

    test('setTextScaleFactor clamps to valid range', () {
      provider.setTextScaleFactor(2.0);
      expect(provider.textScaleFactor, 1.5);

      provider.setTextScaleFactor(0.5);
      expect(provider.textScaleFactor, 0.8);
    });

    test('setTextScaleFactor persists the value', () async {
      provider.setTextScaleFactor(1.2);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('textScaleFactor'), 1.2);
    });

    test('setTextScaleFactor notifies only when value changes', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setTextScaleFactor(1.0); // same as default
      expect(notifyCount, 0);

      provider.setTextScaleFactor(1.2);
      expect(notifyCount, 1);

      provider.setTextScaleFactor(1.2); // same value again
      expect(notifyCount, 1);
    });
  });
}
