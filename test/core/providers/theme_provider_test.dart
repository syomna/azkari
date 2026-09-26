import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('out-of-range stored text scale is clamped on load', () async {
    SharedPreferences.setMockInitialValues({'textScaleFactor': 3.7});

    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs: prefs);

    expect(provider.textScaleFactor, 1.5);
  });

  test('sub-min stored text scale is clamped on load', () async {
    SharedPreferences.setMockInitialValues({'textScaleFactor': 0.2});

    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs: prefs);

    expect(provider.textScaleFactor, 0.8);
  });

  test('clamped value is persisted back to storage', () async {
    SharedPreferences.setMockInitialValues({'textScaleFactor': 3.7});

    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs: prefs);
    provider.setTextScaleFactor(0.25);

    // _savePreferences() is fire-and-forget; let its awaited writes flush.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(provider.textScaleFactor, 0.8);
    final reloaded = ThemeProvider(prefs: prefs);
    expect(reloaded.textScaleFactor, 0.8);
  });
}