import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source_impl.dart';
import 'package:azkar_app/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/names_of_allah/data/datasources/names_of_allah_local_data_source.dart';
import 'package:azkar_app/features/names_of_allah/data/datasources/names_of_allah_local_data_source_impl.dart';
import 'package:azkar_app/features/names_of_allah/data/repositories/names_of_allah_repositoy_impl.dart';
import 'package:azkar_app/features/names_of_allah/domain/repositories/names_of_allah_repository.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/surah/data/datasources/surah_local_data_source.dart';
import 'package:azkar_app/features/surah/data/datasources/surah_local_data_source_impl.dart';
import 'package:azkar_app/features/surah/data/repositories/surah_repositoy_impl.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerSingletonAsync<SharedPreferences>(
    () async => await SharedPreferences.getInstance(),
  );

  // Make sure to await its initialization before other dependencies that depend on it
  await sl.allReady(); 
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  // Azkar
  sl.registerLazySingleton<AzkarLocalDataSource>(
      () => AzkarLocalDataSourceImpl());
  sl.registerLazySingleton<AzkarRepository>(
      () => AzkarRepositoryImpl(azkarLocalDataSource: sl()));
  sl.registerLazySingleton(() => GetAzkarUseCase(azkarRepository: sl()));

  // Names of allah
  sl.registerLazySingleton<NamesOfAllahLocalDataSource>(
      () => NamesOfAllahLocalDataSourceImpl());
  sl.registerLazySingleton<NamesOfAllahRepository>(
      () => NamesOfAllahRepositoyImpl(namesOfAllahLocalDataSource: sl()));
  sl.registerLazySingleton(
      () => GetNamesOfAllahUseCase(namesOfAllahRepository: sl()));

  // Surah
  sl.registerLazySingleton<SurahLocalDataSource>(
      () => SurahLocalDataSourceImpl());
  sl.registerLazySingleton<SurahRepository>(
      () => SurahRepositoyImpl(surahLocalDataSource: sl()));
  sl.registerLazySingleton(() => GetSurahUseCase(surahRepository: sl()));
    sl.registerFactory(() => TasbehProvider(sharedPreferences: sl()));

}
