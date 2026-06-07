import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/providers/locale_provider.dart';
import '../cubits/puzzle_cubit.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/puzzle_action_buttons.dart';
import '../widgets/puzzle_stats.dart';
import '../../data/datasources/puzzle_remote_datasource.dart';
import '../../data/repositories/puzzle_repository_impl.dart';
import '../../domain/usecases/get_random_puzzle.dart';
import '../../domain/usecases/submit_solution.dart';

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  late PuzzleCubit _puzzleCubit;

  @override
  void initState() {
    super.initState();
    _initializePuzzleCubit();
  }

  void _initializePuzzleCubit() {
    final client = Supabase.instance.client;
    final remoteDataSource = PuzzleRemoteDataSourceImpl(client);
    final repository = PuzzleRepositoryImpl(remoteDataSource);

    _puzzleCubit = PuzzleCubit(
      getRandomPuzzle: GetRandomPuzzle(repository),
      submitSolution: SubmitSolution(repository),
      repository: repository,
    );

    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      _puzzleCubit.loadPuzzle(userId);
    }
  }

  @override
  void dispose() {
    _puzzleCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return BlocProvider(
      create: (_) => _puzzleCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(locale.get('puzzles_title')),
          centerTitle: true,
        ),
        body: BlocBuilder<PuzzleCubit, PuzzleState>(
          builder: (context, state) {
            if (state is PuzzleLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PuzzleError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final userId = Supabase.instance.client.auth.currentUser?.id;
                        if (userId != null) {
                          _puzzleCubit.loadPuzzle(userId);
                        }
                      },
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              );
            }

            if (state is PuzzleLoaded) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  PuzzleStats(
                    streak: state.streak,
                    solvedToday: state.solvedToday,
                    progress: state.ratingProgress,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PuzzleBoard(
                      fen: state.fen,
                      userColor: state.userColor,
                      isOpponentTurn: state.isOpponentTurn,
                      isHintShown: state.isHintShown,
                      onMoveMade: (uciMove) {
                        _puzzleCubit.onUserMove(uciMove);
                      },
                    ),
                  ),
                  const PuzzleActionButtons(),
                ],
              );
            }

            if (state is PuzzleSolved) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  PuzzleStats(
                    streak: state.streak,
                    solvedToday: state.solvedToday,
                    progress: state.ratingProgress,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PuzzleBoard(
                      fen: state.fen,
                      userColor: state.userColor,
                      isOpponentTurn: false,
                      isHintShown: false,
                      onMoveMade: (_) {},
                    ),
                  ),
                  const PuzzleActionButtons(),
                ],
              );
            }

            return const Center(child: Text('Загрузка задач...'));
          },
        ),
      ),
    );
  }
}