import '../repositories/puzzle_repository.dart';

class GetUserStats {
  final PuzzleRepository repository;

  GetUserStats(this.repository);

  Future<Map<String, dynamic>> call(String userId) {
    return repository.getUserStats(userId);
  }
}
