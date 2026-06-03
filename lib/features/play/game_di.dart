import 'package:client/features/play/presentation/cubits/matchmaking_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/datasources/ratings_remote_datasource.dart';
import 'data/repositories/matchmaking_repository_impl.dart';
import 'data/repositories/rating_repository_impl.dart';
import 'data/services/game_service.dart';
import 'data/services/stockfish_service.dart';
import 'domain/controllers/bot_controller.dart';
import 'domain/controllers/game_controller.dart';
import 'domain/controllers/local_controller.dart';
import 'domain/controllers/online_controller.dart';
import 'domain/entities/engine_config.dart';
import 'domain/entities/game_config.dart';
import 'domain/repositories/matchmaking_repository.dart';
import 'domain/repositories/rating_repository.dart';


final sl = GetIt.instance;

void initGameDI() {
  // Services
  sl.registerLazySingleton<StockfishService>(() => StockfishService());
  sl.registerLazySingleton<GameService>(() => GameService(Supabase.instance.client));

  // Data Sources
  sl.registerLazySingleton<RatingsRemoteDataSource>(() => RatingsRemoteDataSource(Supabase.instance.client));

  // Repositories
  sl.registerLazySingleton<RatingRepository>(() => RatingRepositoryImpl(sl()));
  sl.registerLazySingleton<MatchmakingRepository>(() => MatchmakingRepositoryImpl(sl()));

  // Controllers
  sl.registerFactoryParam<GameController, String, GameConfig>((mode, config) {
    switch (mode) {
      case 'bot':
        return BotController(
          stockfishService: sl(),
          botLevel: _mapBotLevel(config.engineConfig),
          timeLimitMs: config.engineConfig.timeLimitMs,
        );
      case 'online':
        return OnlineController(
          gameService: sl(),
          gameId: config.gameId ?? '',
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        );
      case 'local':
        return LocalController();
      default:
        return LocalController();
    }
  });

  // Cubits
  sl.registerFactory<MatchmakingCubit>(() => MatchmakingCubit(sl()));
}

int _mapBotLevel(EngineConfig config) {
  // Map engine config to bot level (1-10)
  // This is a simplified mapping - adjust based on your needs
  if (config.timeLimitMs < 500) return 1;
  if (config.timeLimitMs < 1000) return 3;
  if (config.timeLimitMs < 2000) return 5;
  if (config.timeLimitMs < 5000) return 7;
  return 10;
}
