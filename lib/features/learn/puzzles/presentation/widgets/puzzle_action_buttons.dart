import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubits/puzzle_cubit.dart';

class PuzzleActionButtons extends StatelessWidget {
  const PuzzleActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PuzzleCubit, PuzzleState>(
      builder: (context, state) {
        if (state is PuzzleSolved) {
          // After solving: Retry + Next Puzzle
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<PuzzleCubit>().retryPuzzle(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Заново'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final userId = Supabase.instance.client.auth.currentUser?.id;
                      if (userId != null) {
                        context.read<PuzzleCubit>().loadNextPuzzle(userId);
                      }
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Дальше'),
                  ),
                ),
              ],
            ),
          );
        }

        // During puzzle: Hint (1/2 width) + Retry (1/2 width)
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.read<PuzzleCubit>().showHint(),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Подсказка'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.read<PuzzleCubit>().retryPuzzle(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Заново'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
