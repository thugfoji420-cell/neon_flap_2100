import 'package:flutter/foundation.dart';

/// The three selectable game modes. Each maps to a [DifficultyConfig].
enum DifficultyMode {
  easy(name: 'Easy', id: 'easy'),
  normal(name: 'Normal', id: 'normal'),
  hard(name: 'Hard', id: 'hard');

  const DifficultyMode({required this.name, required this.id});
  final String name;
  final String id;

  static DifficultyMode fromId(String id) => DifficultyMode.values
      .firstWhere((e) => e.id == id, orElse: () => DifficultyMode.normal);
}

@immutable
class CoinSpawnConfig {
  const CoinSpawnConfig({
    required this.spawnChance,
    required this.minCoins,
    required this.maxCoins,
    required this.maxActiveCoins,
  })  : assert(spawnChance >= 0 && spawnChance <= 1),
        assert(minCoins >= 0),
        assert(maxCoins >= minCoins),
        assert(maxActiveCoins >= 0);

  final double spawnChance;
  final int minCoins;
  final int maxCoins;
  final int maxActiveCoins;

  double get opportunityRate =>
      spawnChance * ((minCoins + maxCoins) / 2).toDouble();
}

@immutable
class ObstacleMotionConfig {
  const ObstacleMotionConfig({
    required this.enabled,
    required this.amplitude,
    required this.speed,
  })  : assert(amplitude >= 0),
        assert(speed >= 0);

  const ObstacleMotionConfig.disabled()
      : enabled = false,
        amplitude = 0,
        speed = 0;

  final bool enabled;
  final double amplitude;
  final double speed;
}

/// Fully data-driven difficulty configuration.
///
/// All scaling is performed through [speedForScore] / [gapForScore] which
/// clamp to [maxSpeed] / [minGap] so the game can never become impossible.
@immutable
class DifficultyConfig {
  const DifficultyConfig({
    required this.mode,
    required this.baseSpeed,
    required this.maxSpeed,
    required this.speedStep,
    required this.baseGap,
    required this.minGap,
    required this.gapStep,
    required this.stepEvery,
    required this.coinPerScore,
    required this.coinSpawn,
    required this.pipeMotion,
    required this.movingObstacles,
    required this.hazards,
    required this.obstacleBaseSpeed,
    required this.obstacleSpeedStep,
    required this.obstacleBaseFrequency,
    required this.obstacleFrequencyStep,
    required this.maxVerticalGapChange,
  });

  final DifficultyMode mode;
  final double baseSpeed;
  final double maxSpeed;
  final double speedStep;
  final double baseGap;
  final double minGap;
  final double gapStep;
  final int stepEvery;
  final double coinPerScore;
  final CoinSpawnConfig coinSpawn;
  final ObstacleMotionConfig pipeMotion;
  final bool movingObstacles;
  final bool hazards;
  final double obstacleBaseSpeed;
  final double obstacleSpeedStep;
  final double obstacleBaseFrequency;
  final double obstacleFrequencyStep;

  /// Maximum legal centre movement between adjacent randomized openings.
  final double maxVerticalGapChange;

  /// Current scroll speed for a given score, clamped to [maxSpeed].
  double speedForScore(int score) {
    final steps = score ~/ stepEvery;
    return (baseSpeed + steps * speedStep).clamp(baseSpeed, maxSpeed);
  }

  /// Current pipe gap for a given score, clamped to [minGap].
  double gapForScore(int score) {
    final steps = score ~/ stepEvery;
    return (baseGap - steps * gapStep).clamp(minGap, baseGap);
  }

  /// Obstacle speed for a given score (0 when obstacles are disabled).
  double obstacleSpeedForScore(int score) {
    if (!movingObstacles) return 0;
    final steps = score ~/ stepEvery;
    return obstacleBaseSpeed + steps * obstacleSpeedStep;
  }

  /// Probability [0..1] that an obstacle spawns alongside a pipe.
  double obstacleFrequencyForScore(int score) {
    if (!movingObstacles) return 0;
    final steps = score ~/ stepEvery;
    return (obstacleBaseFrequency + steps * obstacleFrequencyStep)
        .clamp(0.0, 1.0);
  }

  /// Factory presets for each mode.
  factory DifficultyConfig.preset(DifficultyMode mode) {
    switch (mode) {
      case DifficultyMode.easy:
        return const DifficultyConfig(
          mode: DifficultyMode.easy,
          // Easy is deliberately forgiving without changing scoring or coin
          // rewards: a small speed reduction, slightly wider openings, and
          // gentler escalation combine to approximately ten percent less
          // challenge. Pipes now use gentle vertical motion so the mode stays
          // dynamic while remaining clearly easier than Normal.
          baseSpeed: 97,
          maxSpeed: 198,
          speedStep: 4.5,
          baseGap: 296,
          minGap: 226,
          gapStep: 1.8,
          stepEvery: 20,
          coinPerScore: 0.15,
          coinSpawn: CoinSpawnConfig(
            spawnChance: 0.35,
            minCoins: 1,
            maxCoins: 2,
            maxActiveCoins: 8,
          ),
          pipeMotion: ObstacleMotionConfig(
            enabled: true,
            amplitude: 28,
            speed: 0.72,
          ),
          movingObstacles: false,
          hazards: false,
          obstacleBaseSpeed: 0,
          obstacleSpeedStep: 0,
          obstacleBaseFrequency: 0,
          obstacleFrequencyStep: 0,
          maxVerticalGapChange: 105,
        );
      case DifficultyMode.normal:
        return const DifficultyConfig(
          mode: DifficultyMode.normal,
          // Keep the currently tuned Normal values unchanged. Easy balancing
          // must not silently alter this mode.
          baseSpeed: 115,
          maxSpeed: 221,
          speedStep: 7,
          baseGap: 296,
          minGap: 197,
          gapStep: 2.5,
          stepEvery: 20,
          coinPerScore: 0.25,
          coinSpawn: CoinSpawnConfig(
            spawnChance: 0.65,
            minCoins: 1,
            maxCoins: 3,
            maxActiveCoins: 16,
          ),
          pipeMotion: ObstacleMotionConfig(
            enabled: true,
            // Normal pipes roam across most of the legal corridor. PipePair
            // clamps this per-spawn so neither wall can enter the gap.
            amplitude: 63,
            speed: 1.15,
          ),
          movingObstacles: true,
          hazards: false,
          obstacleBaseSpeed: 34,
          obstacleSpeedStep: 4,
          obstacleBaseFrequency: 0.17,
          obstacleFrequencyStep: 0.017,
          maxVerticalGapChange: 136,
        );
      case DifficultyMode.hard:
        return const DifficultyConfig(
          mode: DifficultyMode.hard,
          // Keep the currently tuned Hard values unchanged. Its hazards and
          // high-pressure identity remain intact.
          baseSpeed: 159,
          maxSpeed: 301,
          speedStep: 9,
          baseGap: 252,
          minGap: 163,
          gapStep: 2.5,
          stepEvery: 15,
          coinPerScore: 0.40,
          coinSpawn: CoinSpawnConfig(
            spawnChance: 1.0,
            minCoins: 1,
            maxCoins: 3,
            maxActiveCoins: 24,
          ),
          pipeMotion: ObstacleMotionConfig(
            enabled: true,
            amplitude: 92,
            speed: 1.46,
          ),
          movingObstacles: true,
          hazards: true,
          obstacleBaseSpeed: 77,
          obstacleSpeedStep: 9,
          obstacleBaseFrequency: 0.30,
          obstacleFrequencyStep: 0.034,
          maxVerticalGapChange: 167,
        );
    }
  }
}
