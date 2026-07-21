import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:neon_flap1_game/core/utils/neon_paint.dart';

/// A collectible neon coin. Horizontal drift is applied here; the game applies
/// coin-magnet attraction and collision detection against the player.
class Coin extends PositionComponent {
  Coin() : super(anchor: Anchor.center, size: Vector2.all(30));

  Color color = const Color(0xFFffd000);
  int value = 1;
  bool active = false;
  double speed = 150;
  double _spin = 0;
  double _baseY = 0;
  double _motionAmplitude = 0;
  double _motionSpeed = 0;
  double _motionPhase = 0;
  bool _followsGap = false;

  void spawn({
    required Vector2 position,
    required double speed,
    double motionAmplitude = 0,
    double motionSpeed = 0,
    double motionPhase = 0,
  }) {
    this.position.setFrom(position);
    this.speed = speed;
    active = true;
    _spin = 0;
    _baseY = position.y;
    _motionAmplitude = motionAmplitude;
    _motionSpeed = motionSpeed;
    _motionPhase = motionPhase;
    _followsGap = motionAmplitude > 0 && motionSpeed > 0;
  }

  void recycle() {
    active = false;
    position.x = -99999;
  }

  @override
  void update(double dt) {
    if (!active) return;
    position.x -= speed * dt;
    if (_followsGap) {
      _motionPhase += dt * _motionSpeed;
      position.y = _baseY + sin(_motionPhase) * _motionAmplitude;
    }
    _spin += dt * 4;
  }

  /// Moves the coin toward [target] (the player) for the magnet effect.
  void magnetize(Vector2 target, double factor) {
    _followsGap = false;
    position.lerp(target, factor);
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    // Spinning coin rendered as a horizontal squash of a circle.
    final sx = (0.25 + 0.75 * (0.5 + 0.5 * sin(_spin))).clamp(0.12, 1.0);
    drawNeonCircle(canvas, c, size.x * 0.42,
        color: color, glow: 16, fillAlpha: 0.5);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(sx, 1.0);
    drawNeonCircle(canvas, Offset.zero, size.x * 0.42,
        color: color, strokeWidth: 2, glow: 10, fillAlpha: 0.1);
    canvas.restore();
    final core = neonStroke(color, 2, glow: 8);
    canvas.drawLine(Offset(c.dx, c.dy - 6.0), Offset(c.dx, c.dy + 6.0), core);
  }
}
