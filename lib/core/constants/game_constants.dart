/// Core tuning values shared by the Flame game and the dynamic difficulty
/// system. Everything here is a configurable constant so balancing the game
/// never requires touching logic.
library;

class GameConstants {
  const GameConstants._();

  /// Downward acceleration applied to the player every second (logical px/s^2).
  static const double gravity = 1500.0;

  /// Upward velocity injected on a tap (logical px/s).
  static const double jumpImpulse = -470.0;

  /// Player render size (logical px). The hitbox is scaled by the character.
  static const double playerSize = 46.0;

  /// Horizontal thickness of a pipe.
  static const double pipeWidth = 74.0;

  /// Distance between consecutive pipe pairs (logical px).
  static const double pipeSpacing = 290.0;

  /// Default gap (opening) height between top and bottom pipes.
  static const double pipeGap = 210.0;

  /// Vertical size of a moving obstacle block.
  static const double obstacleSize = 60.0;

  /// How close (logical px) a coin must be to be attracted to the player.
  static const double baseCoinAttractionRadius = 0.0;

  /// Fraction of world speed used by moving obstacles.
  static const double obstacleSpeedFactor = 0.5;

  /// Maximum number of pipe pairs kept alive at once (pooling). */
  static const int maxPipePool = 6;

  /// Maximum number of coins/obstacles reused from the pool. */
  static const int maxObjectPool = 24;

  /// Camera viewfinder zoom. Values below 1 zoom the camera OUT, increasing the
  /// visible world area so the player can see roughly three upcoming pipe sets
  /// without changing physics, speed, player size or spawn timing.
  static const double viewZoom = 0.62;
}
