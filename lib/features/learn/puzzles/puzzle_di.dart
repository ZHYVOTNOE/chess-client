// import 'package:get_it/get_it.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'data/datasources/puzzle_remote_datasource.dart';
// import 'data/repositories/puzzle_repository_impl.dart';
// import 'domain/repositories/puzzle_repository.dart';
// import 'domain/usecases/get_random_puzzle.dart';
// import 'domain/usecases/get_puzzle_themes.dart';
// import 'domain/usecases/submit_solution.dart';
// import 'domain/usecases/get_user_stats.dart';
// import 'presentation/cubits/puzzle_cubit.dart';
// import 'package:client/core/providers/locale_provider.dart';
//
// final sl = GetIt.instance;
//
// void initPuzzleDI() {
//   // Data Sources
//   sl.registerLazySingleton<PuzzleRemoteDataSource>(() => PuzzleRemoteDataSourceImpl(Supabase.instance.client));
//
//   // Repositories
//   // sl.registerLazySingleton<PuzzleRepository>(() => PuzzleRepositoryImpl(sl()));
//
//   // Use Cases
//   sl.registerLazySingleton<GetRandomPuzzle>(() => GetRandomPuzzle(sl()));
//   sl.registerLazySingleton<GetPuzzleThemes>(() => GetPuzzleThemes(sl()));
//   sl.registerLazySingleton<SubmitSolution>(() => SubmitSolution(sl()));
//   sl.registerLazySingleton<GetUserStats>(() => GetUserStats(sl()));
//
//   // Cubits
//   sl.registerFactory<PuzzleCubit>(() => PuzzleCubit(
//     getRandomPuzzle: sl(),
//     getThemes: sl(),
//     submitSolution: sl(),
//     getUserStats: sl(),
//     locale: sl<LocaleProvider>(),
//   ));
// }
