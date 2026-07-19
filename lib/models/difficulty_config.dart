import 'package:flutter/foundation.dart';

/// The three selectable game modes. Each maps to a [DifficultyConfig].
enum DifficultyMode {
  easy(name: 'Easy', id: 'easy'),
  normal(name: 'Normal', id: 'normal'),
  hard(name: 'Hard', id: 'hard');

  const DifficultyMode({required this.name, required this.id});
  final String name;
  final String id;

  static DifficultyMode fromId(String id) =>
      DifficultyMode.values.firstWhere((e) => e.id == id,
          orElse: () => DifficultyMode.normal);
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
    required this.movingObstacles,
    required this.hazards,
    required this.obstacleBaseSpeed,
    required this.obstacleSpeedStep,
    required this.obstacleBaseFrequency,
    required this.obstacleFrequencyStep,
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
  final bool movingObstacles;
  final bool hazards;
  final double obstacleBaseSpeed;
  final double obstacleSpeedStep;
  final double obstacleBaseFrequency;
  final double obstacleFrequencyStep;

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
          baseSpeed: 90,
          maxSpeed: 180,
          speedStep: 4,
          baseGap: 320,
          minGap: 240,
          gapStep: 2,
          stepEvery: 20,
          coinPerScore: 0.15,
          movingObstacles: false,
          hazards: false,
          obstacleBaseSpeed: 0,
          obstacleSpeedStep: 0,
          obstacleBaseFrequency: 0,
          obstacleFrequencyStep: 0,
        );
      case DifficultyMode.normal:
        return const DifficultyConfig(
          mode: DifficultyMode.normal,
          baseSpeed: 130,
          maxSpeed: 250,
          speedStep: 7,
          baseGap: 270,
          minGap: 180,
          gapStep: 3,
          stepEvery: 20,
          coinPerScore: 0.25,
          movingObstacles: true,
          hazards: false,
          obstacleBaseSpeed: 40,
          obstacleSpeedStep: 5,
          obstacleBaseFrequency: 0.20,
          obstacleFrequencyStep: 0.02,
        );
      case DifficultyMode.hard:
        return const DifficultyConfig(
          mode: DifficultyMode.hard,
          baseSpeed: 180,
          maxSpeed: 340,
          speedStep: 10,
          baseGap: 230,
          minGap: 150,
          gapStep: 3,
          stepEvery: 15,
          coinPerScore: 0.40,
          movingObstacles: true,
          hazards: true,
          obstacleBaseSpeed: 90,
          obstacleSpeedStep: 11,
          obstacleBaseFrequency: 0.35,
          obstacleFrequencyStep: 0.04,
        );
    }
  }
}

