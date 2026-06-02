import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/usecases/get_profile_usecase.dart';
import 'domain/usecases/update_profile_usecase.dart';
import 'domain/usecases/update_full_name_usecase.dart';
import 'domain/usecases/update_bio_usecase.dart';
import 'domain/usecases/update_country_code_usecase.dart';
import 'presentation/cubits/profile_cubit.dart';
import '../../../core/services/location_service.dart';

final sl = GetIt.instance;

void initProfile() {
  // Data
  sl.registerLazySingleton(() => ProfileRemoteDatasource(Supabase.instance.client));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));

  // Domain
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateNickname(sl()));
  sl.registerLazySingleton(() => UpdateAvatar(sl()));
  sl.registerLazySingleton(() => UpdateFullName(sl()));
  sl.registerLazySingleton(() => UpdateBio(sl()));
  sl.registerLazySingleton(() => UpdateCountryCode(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));

  // Core Services
  sl.registerLazySingleton(() => LocationService());

  // Presentation
  sl.registerFactory(() => ProfileCubit(
    sl(),
    sl(),
    sl(),
    sl(),
    sl(),
    sl(),
    sl(),
    sl(),
  ));
}