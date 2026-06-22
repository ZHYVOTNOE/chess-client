import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../matchmaking/data/websocket_service.dart';
import '../matchmaking/presentation/cubits/matchmaking_cubit.dart';
import 'data/datasources/ratings_remote_datasource.dart';
import 'data/repositories/game_setup_repository_impl.dart';
import 'data/repositories/rating_repository_impl.dart';
import 'data/services/game_service.dart';
import 'data/services/stockfish_service.dart';
import 'domain/controllers/bot_controller.dart';
import 'domain/controllers/game_controller.dart';
import 'domain/controllers/local_controller.dart';
import 'domain/entities/engine_config.dart';
import 'domain/entities/game_config.dart';
import 'domain/repositories/game_setup_repository.dart';
import 'domain/repositories/rating_repository.dart';


final sl = GetIt.instance;

void initGameDI() {
  // Services
  sl.registerLazySingleton<StockfishService>(() => StockfishService());
  sl.registerLazySingleton<GameService>(() => GameService(Supabase.instance.client));
  sl.registerLazySingleton<MatchmakingWebSocketService>(() => MatchmakingWebSocketService(
    serverUrl: 'ws://91.149.179.215:8080/ws',
  ));

  // Data Sources
  sl.registerLazySingleton<RatingsRemoteDataSource>(() => RatingsRemoteDataSource(Supabase.instance.client));

  // Repositories
  sl.registerLazySingleton<RatingRepository>(() => RatingRepositoryImpl(sl()));
  sl.registerLazySingleton<GameSetupRepository>(() => GameSetupRepositoryImpl(Supabase.instance.client));

  // Controllers
  sl.registerFactoryParam<GameController, String, GameConfig>((mode, config) {
    switch (mode) {
      case 'bot':
        return BotController(
          stockfishService: sl(),
          botLevel: _mapBotLevel(config.engineConfig),
          timeLimitMs: config.engineConfig.timeLimitMs,
        );
      // case 'online':
      //   return OnlineController(
      //     gameService: sl(),
      //     gameId: config.gameId ?? '',
      //     userId: Supabase.instance.client.auth.currentUser?.id ?? '',
      //   );
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
  // Map engine config maxDepth to Stockfish bot level (1-10)
  // The maxDepth in EngineConfig now directly corresponds to Stockfish level
  return config.maxDepth ?? 5;
}
