import '../entities/puzzle.dart';
import '../repositories/puzzle_repository.dart';

class GetRandomPuzzle {
  final PuzzleRepository repository;

  GetRandomPuzzle(this.repository);

  Future<Puzzle> call(String userId) {
    return repository.getRandomPuzzle(userId);
  }
}
