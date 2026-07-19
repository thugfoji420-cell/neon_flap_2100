import 'package:neon_flap1_game/models/difficulty_config.dart';

/// Summary of a finished run, passed from the reward screen to game over.
class RunResult {
  const RunResult({
    required this.score,
    required this.best,
    required this.coinsEarned,
    required this.mode,
    required this.characterId,
    required this.totalFlaps,
  });

  final int score;
  final int best;
  final int coinsEarned;
  final DifficultyMode mode;
  final String characterId;
  final int totalFlaps;
}
