import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/locale_provider.dart';
import 'data/datasources/settings_remote_datasource.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/settings_repository.dart';
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
    () => SettingsRepositoryImpl(sl<SettingsRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton<GetSettings>(
    () => GetSettings(sl<SettingsRepository>()),
  );
  sl.registerLazySingleton<SaveSettings>(
    () => SaveSettings(sl<SettingsRepository>()),
  );

  // Cubits
  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      sl<GetSettings>(),
      sl<SaveSettings>(),
      sl<LocaleProvider>(),
    ),
  );
}
