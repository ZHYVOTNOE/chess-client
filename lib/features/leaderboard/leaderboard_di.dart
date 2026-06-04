import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/repositories/leaderboard_repository_impl.dart';
import 'domain/repositories/leaderboard_repository.dart';
import 'domain/usecases/get_leaderboard_usecase.dart';
import 'domain/usecases/get_user_rank_usecase.dart';
import 'presentation/cubits/leaderboard_cubit.dart';

final sl = GetIt.instance;

void initLeaderboardDI() {
  // Repositories
  sl.registerLazySingleton<LeaderboardRepository>(() => LeaderboardRepositoryImpl(Supabase.instance.client));

  // Use Cases
  sl.registerLazySingleton<GetLeaderboardUseCase>(() => GetLeaderboardUseCase(sl()));
  sl.registerLazySingleton<GetUserRankUseCase>(() => GetUserRankUseCase(sl()));

  // Cubits
  sl.registerFactory<LeaderboardCubit>(() => LeaderboardCubit(sl(), sl(), sl(), Supabase.instance.client));
}
