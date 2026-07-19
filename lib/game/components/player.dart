import 'dart:ui';

import 'package:flame/components.dart';

import 'package:neon_flap1_game/core/constants/game_constants.dart';
import 'package:neon_flap1_game/core/utils/neon_paint.dart';
import 'package:neon_flap1_game/models/character.dart';

/// The player's neon bird. All physics and rendering are procedural;
/// collisions are detected manually by the game using [hitboxRadius] for
/// precise, pooling-friendly collision tests.
class Player extends PositionComponent {
  Player({required this.character})
      : super(anchor: Anchor.center, size: Vector2.all(GameConstants.playerSize));

  final Character character;

  double velocityY = 0;
  double _wobble = 0;
  bool dead = false;
  bool frozen = false;

  double get hitboxRadius => size.x * 0.30 * character.stats.hitboxScale;

  /// Tap response: a precise upward impulse scaled subtly by jump precision.
  void flap() {
    velocityY = GameConstants.jumpImpulse *
        character.stats.jumpPrecision.clamp(0.92, 1.18);
    // Kick the wing into an upstroke on every flap.
    _wobble += 1.2;
  }

  @override
  void update(double dt) {
    if (dead || frozen) return;
    final g = GameConstants.gravity * character.stats.gravityScale;
    velocityY += g * dt;
    // "Control" reduces the maximum fall speed for a more forgiving feel.
    final maxFall = 820 * (2 - character.stats.control).clamp(0.6, 1.4);
    if (velocityY > maxFall) velocityY = maxFall;
    position.y += velocityY * dt;
    // Wings flap faster while rising, slower while gliding down.
    _wobble += dt * (10 + velocityY * -0.012);
  }

  @override
  void render(Canvas canvas) {
    final c = character;
    final s = size.x;
    final center = Offset(s / 2, s / 2);

    // Tilt the bird to dive when falling and pitch up when rising.
    final tilt = (velocityY / 900).clamp(-0.5, 0.7);
    // Engine/aura glow pulses subtly with velocity.
    final glow = 12 + 8 * (1 + velocityY / 900).clamp(0.0, 1.0);

    drawNeonBird(
      canvas,
      center,
      s,
      primary: c.primary,
      accent: c.accent,
      wingPhase: _wobble,
      tilt: tilt,
      glow: glow,
    );
  }
}
