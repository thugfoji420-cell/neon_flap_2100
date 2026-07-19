import 'package:neon_flap1_game/models/difficulty_config.dart';

/// Resolves the active [DifficultyConfig] for a chosen mode and exposes the
/// dynamic values (speed/gap/obstacle behaviour) for any score. All scaling
/// lives in [DifficultyConfig], keeping this layer pure and testable.
///
/// The [config] is created once on construction and reused — the preset values
/// are fixed per mode and do not change during gameplay.
class DifficultyService {
  DifficultyService(this.mode) : _config = DifficultyConfig.preset(mode);

  final DifficultyMode mode;
  final DifficultyConfig _config;

  /// The parsed configuration for this mode. Read once and cached to avoid
  /// reconstructing the preset (which creates a new const object) on every
  /// per-frame access via [speedAt] and [gapAt].
  DifficultyConfig get config => _config;

  /// Scroll speed for a given score (clamped to the mode's max).
  double speedAt(int score) => _config.speedForScore(score);

  /// Pipe gap for a given score (clamped to the mode's minimum).
  double gapAt(int score) => _config.gapForScore(score);
}
