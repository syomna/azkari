import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'tasbeh_provider_test.mocks.mocks.dart';

void main() {
  late TasbehProvider tasbehProvider;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    when(mockSharedPreferences.getInt(any)).thenReturn(0);
    tasbehProvider = TasbehProvider(sharedPreferences: mockSharedPreferences);
  });

  group('tasbehProvider', () {
    test('should return initial counts', () {
      when(mockSharedPreferences.getInt('total_tasbeh_count')).thenReturn(150);
      when(mockSharedPreferences.getInt('current_session_tasbeh_count'))
          .thenReturn(25);
      tasbehProvider.loadCount();
      expect(tasbehProvider.savedCount, 150);
      expect(tasbehProvider.count, 25);
      verify(mockSharedPreferences.getInt('total_tasbeh_count'))
          .called(greaterThanOrEqualTo(1));
      verify(mockSharedPreferences.getInt('current_session_tasbeh_count'))
          .called(greaterThanOrEqualTo(1));
    });

    test(
      'should increment counts and save to SharedPreferences when addCount is called',
      () async {
        // Arrange
        when(mockSharedPreferences.setInt(any, any))
            .thenAnswer((_) async => true);

        // Act
        await tasbehProvider.addCount();
        await tasbehProvider.addCount();

        // Assert
        expect(tasbehProvider.count, 2);
        expect(tasbehProvider.savedCount, 2);

        verify(mockSharedPreferences.setInt('total_tasbeh_count', 1)).called(1);
        verify(mockSharedPreferences.setInt('total_tasbeh_count', 2)).called(1);
        verify(mockSharedPreferences.setInt('current_session_tasbeh_count', 1))
            .called(1);
        verify(mockSharedPreferences.setInt('current_session_tasbeh_count', 2))
            .called(1);

        verifyNoMoreInteractions(mockSharedPreferences); // This should now pass
      },
    );

    test(
        'should reset current_session_tasbeh_count and save it to SharedPreferences',
        () async {
      when(mockSharedPreferences.setInt(any, any))
          .thenAnswer((_) async => true);
      await tasbehProvider.addCount();
      await tasbehProvider.addCount();
      await tasbehProvider.reset();
      expect(tasbehProvider.count, 0);
      expect(tasbehProvider.savedCount, 2);
      verify(mockSharedPreferences.setInt('current_session_tasbeh_count', 0))
          .called(1);
    });

    test(
        'should reset all and save it to SharedPreferences',
        () async {
      when(mockSharedPreferences.setInt(any, any))
          .thenAnswer((_) async => true);
      await tasbehProvider.addCount();
      await tasbehProvider.addCount();
      await tasbehProvider.resetAll();
      expect(tasbehProvider.count, 0);
      expect(tasbehProvider.savedCount, 0);
      verify(mockSharedPreferences.setInt('current_session_tasbeh_count', 0))
          .called(1);
          verify(mockSharedPreferences.setInt('total_tasbeh_count', 0))
          .called(1);
    });
  });
}
