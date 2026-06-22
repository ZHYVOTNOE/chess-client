import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/settings_provider.dart';
import 'data/datasources/settings_remote_datasource.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/settings_repository.dart' as domain;
import 'domain/usecases/get_settings_usecase.dart';
import 'domain/usecases/save_settings_usecase.dart';
import 'presentation/cubits/settings_cubit.dart';

final sl = GetIt.instance;

void initSettingsDI() {
  // Datasources
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSource(Supabase.instance.client),
  );

  // Repositories
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<domain.SettingsRepository>(
    () => SettingsRepositoryImpl(sl<SettingsRemoteDataSource>()),
  );

  // Providers
  sl.registerLazySingleton<SettingsProvider>(
    () => SettingsProvider(sl<SettingsRepository>()),
  );

  // Use cases
  sl.registerLazySingleton<GetSettings>(
    () => GetSettings(sl<domain.SettingsRepository>()),
  );
  sl.registerLazySingleton<SaveSettings>(
    () => SaveSettings(sl<domain.SettingsRepository>()),
  );

  // Cubits
  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      sl<GetSettings>(),
      sl<SaveSettings>(),
      sl<LocaleProvider>(),
      sl<SettingsProvider>(),
    ),
  );
}
