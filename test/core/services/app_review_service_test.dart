import 'package:azkar_app/core/services/app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppReviewService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('counts launches and prompts on every 5th launch', () async {
      for (var i = 1; i <= 10; i++) {
        expect(
          await AppReviewService.shouldPromptOnLaunch(),
          i % 5 == 0,
          reason: 'فتحة رقم $i',
        );
      }
    });

    test('resumes counting from the saved value', () async {
      await AppReviewService.shouldPromptOnLaunch();
      await AppReviewService.shouldPromptOnLaunch();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppReviewService.launchCountKey), 2);
    });
  });
}
