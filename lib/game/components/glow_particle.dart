import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:neon_flap1_game/core/utils/neon_paint.dart';

class _Spark {
  _Spark(this.angle, this.speed);
  final double angle;
  final double speed;
  double life = 1.0;
}

/// A short-lived radial burst of glowing sparks used for coin pickups and the
/// crash effect. Self-removes when all sparks fade.
class GlowBurst extends PositionComponent {
  GlowBurst({
    required Vector2 position,
    required this.color,
    this.count = 12,
    this.maxSpeed = 160,
    this.radius = 5,
  }) : super(anchor: Anchor.center, position: position);

  final Color color;
  final int count;
  final double maxSpeed;
  final double radius;
  final List<_Spark> _sparks = [];
  final Random _rnd = Random();

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < count; i++) {
      _sparks.add(_Spark(
        _rnd.nextDouble() * 6.283,
        40 + _rnd.nextDouble() * maxSpeed,
      ));
    }
    await super.onLoad();
  }

  @override
  void update(double dt) {
    var alive = false;
    for (final s in _sparks) {
      s.life -= dt * 1.8;
      if (s.life > 0) alive = true;
    }
    if (!alive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final s in _sparks) {
      if (s.life <= 0) continue;
      final d = (1 - s.life) * s.speed;
      final p = Offset(cos(s.angle) * d, sin(s.angle) * d);
      canvas.drawCircle(
        p,
        radius * s.life,
        neonFill(color, glow: 10, alpha: s.life * 0.8),
      );
    }
  }
}
