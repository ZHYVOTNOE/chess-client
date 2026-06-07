import '../repositories/puzzle_repository.dart';

class SubmitSolution {
  final PuzzleRepository repository;

  SubmitSolution(this.repository);

  Future<bool> call({
    required String puzzleId,
    required List<String> moves,
  }) {
    return repository.submitSolution(
      puzzleId: puzzleId,
      moves: moves,
    );
  }
}
