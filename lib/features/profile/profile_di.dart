import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Play feature — только типы для типизации, БЕЗ регистрации
import '../play/domain/repositories/rating_repository.dart';
import '../play/data/datasources/ratings_remote_datasource.dart';

// Profile feature
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/usecases/check_nickname_availability_usecase.dart';
import 'domain/usecases/get_profile_usecase.dart';
import 'domain/usecases/update_full_name_usecase.dart';
import 'domain/usecases/update_bio_usecase.dart';
import 'domain/usecases/update_country_code_usecase.dart';
// ✅ Один импорт для всех трёх классов (UpdateNickname, UpdateAvatar, UpdateProfile)
import 'domain/usecases/update_profile_usecase.dart';
import 'presentation/cubits/profile_cubit.dart';
import '../../core/services/location_service.dart';

final sl = GetIt.instance;

void initProfile() {
  // ❌ НЕ регистрируем здесь RatingsRemoteDataSource и RatingRepository — они уже в game_di!

  // Profile — Data
  sl.registerLazySingleton(() => ProfileRemoteDatasource(Supabase.instance.client));
  sl.registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(
      sl<ProfileRemoteDatasource>(),
      sl<RatingRepository>(),
    ),
  );

  // Profile — Use Cases
  sl.registerLazySingleton(() => GetProfile(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateNickname(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateAvatar(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateFullName(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateBio(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateCountryCode(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfile(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => CheckNicknameAvailability(sl<ProfileRepository>()));

  // Core
  if (!sl.isRegistered<LocationService>()) {
    sl.registerLazySingleton(() => LocationService());
  }

  // Profile — Cubit
  sl.registerFactory<ProfileCubit>(
        () => ProfileCubit(
      sl<GetProfile>(),
      sl<UpdateNickname>(),
      sl<UpdateAvatar>(),
      sl<UpdateFullName>(),
      sl<UpdateBio>(),
      sl<UpdateCountryCode>(),
      sl<UpdateProfile>(),
      sl<CheckNicknameAvailability>(),
      sl<LocationService>(),
      sl<RatingRepository>(),
      sl<RatingsRemoteDataSource>(),
    ),
  );
}