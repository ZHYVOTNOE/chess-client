import '../repositories/puzzle_repository.dart';

class GetPuzzleThemes {
  final PuzzleRepository repository;

  GetPuzzleThemes(this.repository);

  Future<List<String>> call() {
    return repository.getThemes();
  }
}
