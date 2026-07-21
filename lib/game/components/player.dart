import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/characters/character_sprite_catalog.dart';
import 'package:neon_flap1_game/core/constants/game_constants.dart';
import 'package:neon_flap1_game/models/character.dart';

/// The player's illustrated neon bird. Physics remain independent of its large
/// visual canvas: collision tests use only the forgiving central torso radius.
class Player extends PositionComponent {
  Player({required this.character})
      : super(
            anchor: Anchor.center, size: Vector2.all(GameConstants.playerSize));

  final Character character;

  double velocityY = 0;
  double _wingPhase = 0;
  double _tapGlow = 0;
  Image? _spriteSheet;
  bool dead = false;
  bool frozen = false;

  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.high;
  final Paint _shadowPaint = Paint()..filterQuality = FilterQuality.high;
  final Paint _outerGlowPaint = Paint()..filterQuality = FilterQuality.high;
  final Paint _innerGlowPaint = Paint()..filterQuality = FilterQuality.high;

  double get hitboxRadius => size.x * 0.30 * character.stats.hitboxScale;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _spriteSheet = await CharacterSpriteCache.load(character.id);
    } catch (error) {
      // The game preloads this asset before player construction. Falling back
      // to Nova avoids an invisible player if a local character sheet is bad.
      debugPrint('Unable to load player sprite ${character.id}: $error');
      try {
        _spriteSheet = await CharacterSpriteCache.load('nova');
      } catch (fallbackError) {
        debugPrint('Unable to load fallback player sprite: $fallbackError');
      }
    }
    final visual = character.gameplayVisual;
    final canvasSize = size.x;
    _shadowPaint
      ..color = const Color(0xFF01050A).withOpacity(0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, canvasSize * 0.055);
    _outerGlowPaint.maskFilter =
        MaskFilter.blur(BlurStyle.normal, canvasSize * visual.glowRadius);
    _innerGlowPaint.maskFilter =
        MaskFilter.blur(BlurStyle.normal, canvasSize * 0.045);
  }

  /// Tap response: a precise upward impulse scaled subtly by jump precision.
  void flap() {
    velocityY = GameConstants.jumpImpulse *
        character.stats.jumpPrecision.clamp(0.92, 1.18);
    // A tap brightens the current natural stroke; it never resets phase.
    _tapGlow = 1;
  }

  @override
  void update(double dt) {
    if (dead) {
      return;
    }
    if (frozen) {
      return;
    }
    final g = GameConstants.gravity * character.stats.gravityScale;
    velocityY += g * dt;
    // "Control" reduces the maximum fall speed for a more forgiving feel.
    final maxFall = 820 * (2 - character.stats.control).clamp(0.6, 1.4);
    if (velocityY > maxFall) velocityY = maxFall;
    position.y += velocityY * dt;
    _advanceWingCycle(dt);
  }

  /// Advances a single time-based cycle. Rising makes the existing illustrated
  /// stroke subtly livelier; falling slows it without freezing it mid-air.
  void _advanceWingCycle(double dt) {
    final visual = character.gameplayVisual;
    final velocityPace = velocityY < -100
        ? 1.18
        : velocityY > 260
            ? 0.78
            : 1.0;
    final tapPace = 1 + _tapGlow * 0.22;
    _wingPhase =
        (_wingPhase + dt * velocityPace * tapPace / visual.flapCycleDuration) %
            1;
    _tapGlow = (_tapGlow - dt * 4.5).clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    final sheet = _spriteSheet;
    if (sheet == null) return;
    final s = size.x;
    final visual = character.gameplayVisual;

    final tilt = (velocityY / 900).clamp(-0.5, 0.7);
    final source = CharacterSpriteCatalog.sourceRect(_currentFrame);
    final center = Offset(
      s / 2 + visual.offset.dx,
      s / 2 + visual.offset.dy,
    );
    final artworkRect = Rect.fromCenter(
      center: center,
      width: s * visual.scale,
      height: s * visual.scale,
    );
    final glowRect = artworkRect.inflate(s * 0.035);

    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(tilt);
    canvas.translate(-s / 2, -s / 2);

    _outerGlowPaint.color = character.primary.withOpacity(
      (visual.glowOpacity + _tapGlow * visual.tapGlowBoost).clamp(0, 0.62),
    );
    _innerGlowPaint.color = character.accent.withOpacity(
      (visual.innerGlowOpacity + _tapGlow * 0.06).clamp(0, 0.30),
    );

    // A compact shadow plus two cached glow layers separates every silhouette
    // from the game world without changing its component size or hitbox.
    canvas.drawImageRect(
      sheet,
      source,
      artworkRect.shift(Offset(0, s * 0.025)),
      _shadowPaint,
    );
    canvas.drawImageRect(
      sheet,
      source,
      glowRect,
      _outerGlowPaint,
    );
    canvas.drawImageRect(
      sheet,
      source,
      artworkRect,
      _innerGlowPaint,
    );

    canvas.drawImageRect(
      sheet,
      source,
      artworkRect,
      _spritePaint,
    );
    canvas.restore();
  }

  CharacterSpriteFrame get _currentFrame {
    if (dead || velocityY >= 560) return CharacterSpriteFrame.fall;
    if (frozen) return CharacterSpriteFrame.idle;
    return CharacterSpriteCatalog.gameplayFrameForProgress(_wingPhase);
  }
}
