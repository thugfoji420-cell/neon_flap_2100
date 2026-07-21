import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'package:neon_flap1_game/core/constants/game_constants.dart';
import 'package:neon_flap1_game/core/utils/neon_paint.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';

/// One neon pipe segment. Rendered procedurally; collision is handled by the
/// parent [PipePair] via axis-aligned rects for precise, pool-friendly tests.
class PipeBody extends PositionComponent {
  PipeBody() : super(anchor: Anchor.topLeft);

  Color color = const Color(0xFF00f0ff);
  double renderPhase = 0;

  @override
  void render(Canvas canvas) {
    drawNeonBar(
      canvas,
      size.toRect(),
      color: color,
      glow: 14,
      phase: renderPhase,
    );
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
  double _gap = 0;
  double _baseCenterY = 0;
  double _currentCenterY = 0;
  double _motionAmplitude = 0;
  double _motionSpeed = 0;
  double _motionPhase = 0;
  double _renderPhase = 0;

  double get gapCenterY => _currentCenterY;
  double get baseCenterY => _baseCenterY;
  double get motionAmplitude => _motionAmplitude;
  double get motionSpeed => _motionSpeed;
  double get motionPhase => _motionPhase;

  void spawn({
    required double x,
    required double centerY,
    required double gap,
    required double speed,
    required double worldHeight,
    required Color color,
    ObstacleMotionConfig motion = const ObstacleMotionConfig.disabled(),
    double? minCenterY,
    double? maxCenterY,
    double motionPhase = 0,
  }) {
    this.speed = speed;
    this.worldHeight = worldHeight;
    passed = false;
    active = true;
    _gap = gap;
    _baseCenterY = centerY;
    _currentCenterY = centerY;
    final minCenter = minCenterY ?? gap / 2;
    final maxCenter = maxCenterY ?? worldHeight - gap / 2;
    final maxSafeAmplitude = [
      centerY - minCenter,
      maxCenter - centerY,
      motion.amplitude,
    ].reduce((a, b) => a < b ? a : b);
    _motionAmplitude = motion.enabled
        ? maxSafeAmplitude.clamp(0, motion.amplitude).toDouble()
        : 0;
    _motionSpeed = motion.enabled ? motion.speed : 0;
    _motionPhase = motionPhase;
    _renderPhase = motionPhase / (2 * pi);
    _top.renderPhase = _renderPhase;
    _bottom.renderPhase = _renderPhase + 0.5;

    position = Vector2(x, 0);
    _top.color = color;
    _top.position = Vector2.zero();
    _bottom.color = color;
    _layoutForCenter(centerY);
  }

  void recycle() {
    active = false;
    position.x = -99999;
  }

  @override
  void update(double dt) {
    if (!active) return;
    position.x -= speed * dt;
    _renderPhase = (_renderPhase + dt * (0.8 + speed / 260)) % 1;
    _top.renderPhase = _renderPhase;
    _bottom.renderPhase = (_renderPhase + 0.5) % 1;
    if (_motionAmplitude > 0 && _motionSpeed > 0) {
      _motionPhase += dt * _motionSpeed;
      _layoutForCenter(_baseCenterY + sin(_motionPhase) * _motionAmplitude);
    }
  }

  void _layoutForCenter(double centerY) {
    _currentCenterY =
        centerY.clamp(_gap / 2, worldHeight - _gap / 2).toDouble();
    topHeight = (_currentCenterY - _gap / 2).clamp(0, worldHeight).toDouble();
    bottomY = _currentCenterY + _gap / 2;
    _top.size = Vector2(GameConstants.pipeWidth, topHeight);
    _bottom.size = Vector2(
      GameConstants.pipeWidth,
      (worldHeight - bottomY).clamp(0, worldHeight).toDouble(),
    );
    _bottom.position = Vector2(0, bottomY);
  }

  /// Right edge in world space — scoring happens when the gap opening passes
  /// the player. Both pipe walls share the same horizontal edge, so collision,
  /// score timing and the visible opening remain aligned.
  double get rightEdge => position.x + GameConstants.pipeWidth;

  Rect get topRect =>
      Rect.fromLTWH(position.x, 0, GameConstants.pipeWidth, topHeight);
  Rect get bottomRect => Rect.fromLTWH(position.x, bottomY,
      GameConstants.pipeWidth, (worldHeight - bottomY).clamp(0, worldHeight));
}
