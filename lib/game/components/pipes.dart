import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'package:neon_flap_2100/core/constants/game_constants.dart';
import 'package:neon_flap_2100/core/utils/neon_paint.dart';

/// One neon pipe segment. Rendered procedurally; collision is handled by the
/// parent [PipePair] via axis-aligned rects for precise, pool-friendly tests.
class PipeBody extends PositionComponent {
  PipeBody() : super(anchor: Anchor.topLeft);

  Color color = const Color(0xFF00f0ff);

  @override
  void render(Canvas canvas) {
    drawNeonBar(canvas, size.toRect(), color: color, glow: 14);
  }
}

/// A top/bottom pipe pair with a gap. Designed to be recycled (pooled) by the
/// game: [spawn] reconfigures it, [recycle] parks it off-screen.
class PipePair extends PositionComponent {
  PipePair() : super(anchor: Anchor.topLeft) {
    _top = PipeBody();
    _bottom = PipeBody();
    add(_top);
    add(_bottom);
  }

  late final PipeBody _top;
  late final PipeBody _bottom;

  double speed = 150;
  double worldHeight = 0;
  double topHeight = 0;
  double bottomY = 0;
  bool passed = false;
  bool active = false;

  void spawn({
    required double x,
    required double centerY,
    required double gap,
    required double speed,
    required double worldHeight,
    required Color color,
  }) {
    this.speed = speed;
    this.worldHeight = worldHeight;
    passed = false;
    active = true;

    topHeight = (centerY - gap / 2).clamp(0, worldHeight);
    bottomY = centerY + gap / 2;

    position = Vector2(x, 0);
    _top.color = color;
    _top.size = Vector2(GameConstants.pipeWidth, topHeight);
    _top.position = Vector2.zero();
    _bottom.color = color;
    _bottom.size = Vector2(GameConstants.pipeWidth,
        (worldHeight - bottomY).clamp(0, worldHeight));
    _bottom.position = Vector2(0, bottomY);
  }

  void recycle() {
    active = false;
    position.x = -99999;
  }

  @override
  void update(double dt) {
    if (!active) return;
    position.x -= speed * dt;
  }

  /// Right edge in world space (used for scoring).
  double get rightEdge => position.x + GameConstants.pipeWidth;

  Rect get topRect => Rect.fromLTWH(
      position.x, 0, GameConstants.pipeWidth, topHeight);
  Rect get bottomRect => Rect.fromLTWH(position.x, bottomY,
      GameConstants.pipeWidth, (worldHeight - bottomY).clamp(0, worldHeight));
}
