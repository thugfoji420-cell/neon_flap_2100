import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:neon_flap1_game/core/constants/game_constants.dart';
import 'package:neon_flap1_game/core/utils/neon_paint.dart';

/// Behaviour of a non-pipe obstacle.
enum ObstacleKind {
  /// Slowly drifting block (Normal / Hard), oscillates vertically.
  drifting,

  /// Fast horizontal hazard (Hard only).
  hazard,
}

/// A moving obstacle block. Collision rects are exposed for manual AABB tests.
class Obstacle extends PositionComponent {
  Obstacle()
      : super(
          anchor: Anchor.center,
          size: Vector2.all(GameConstants.obstacleSize),
        );

  Color color = const Color(0xFFff2bd6);
  ObstacleKind kind = ObstacleKind.drifting;
  bool active = false;

  double _t = 0;
  double _baseY = 0;
  double _amp = 0;
  double _horizSpeed = 0;
  double worldHeight = 0;

  void spawn({
    required double x,
    required double baseY,
    required double amplitude,
    required double horizontalSpeed,
    required double worldHeight,
    required ObstacleKind kind,
    required Color color,
  }) {
    this.kind = kind;
    this.color = color;
    this.worldHeight = worldHeight;
    _baseY = baseY.clamp(size.y, worldHeight - size.y);
    _amp = amplitude;
    _horizSpeed = horizontalSpeed;
    _t = 0;
    active = true;
    position = Vector2(x, _baseY);
  }

  void recycle() {
    active = false;
    position.x = -99999;
  }

  @override
  void update(double dt) {
    if (!active) return;
    _t += dt;
    position.x -= _horizSpeed * dt;
    if (kind == ObstacleKind.drifting) {
      position.y =
          (_baseY + sin(_t * 2.2) * _amp).clamp(size.y, worldHeight - size.y);
    } else {
      // Hazard weaves slightly for a threatening feel.
      position.y = (_baseY + sin(_t * 5.0) * (_amp * 0.4))
          .clamp(size.y, worldHeight - size.y);
    }
  }

  Rect get rect => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: size.x,
        height: size.y,
      );

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final c = Offset(s / 2, s / 2);
    final double glow = kind == ObstacleKind.hazard ? 24 : 14;
    // Rotating warning diamond.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_t * (kind == ObstacleKind.hazard ? 3 : 1.2));
    final path = Path()
      ..moveTo(0.0, -s * 0.45)
      ..lineTo(s * 0.45, 0.0)
      ..lineTo(0.0, s * 0.45)
      ..lineTo(-s * 0.45, 0.0)
      ..close();
    canvas.drawPath(path, neonFill(color, glow: glow, alpha: 0.25));
    canvas.drawPath(path, neonStroke(color, 3, glow: glow));
    canvas.restore();
  }
}
