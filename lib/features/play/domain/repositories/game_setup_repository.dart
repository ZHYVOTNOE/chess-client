import '../entities/game_setup.dart';

abstract class GameSetupRepository {
  Future<GameSetup?> getGameSetup(String userId);
  Future<void> saveGameSetup(GameSetup gameSetup);
}
