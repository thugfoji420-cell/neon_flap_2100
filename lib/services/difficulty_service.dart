import 'package:neon_flap_2100/models/difficulty_config.dart';

/// Resolves the active [DifficultyConfig] for a chosen mode and exposes the
/// dynamic values (speed/gap/obstacle behaviour) for any score. All scaling
/// lives in [DifficultyConfig], keeping this layer pure and testable.
class DifficultyService {
  DifficultyService(this.mode);

  final DifficultyMode mode;

  DifficultyConfig get config => DifficultyConfig.preset(mode);

  /// Scroll speed for a given score (clamped to the mode's max).
  double speedAt(int score) => config.speedForScore(score);

  /// Pipe gap for a given score (clamped to the mode's minimum).
  double gapAt(int score) => config.gapForScore(score);
}
