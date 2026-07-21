import 'package:flutter/foundation.dart';
import 'dart:ui';

enum CharacterTier { standard, premium, elite, legendary }

/// Per-character gameplay modifiers. Base values are 1.0; better (paid)
/// characters nudge these to improve feel without becoming overpowered.
@immutable
class CharacterStats {
  const CharacterStats({
    this.control = 1.0,
    this.jumpPrecision = 1.0,
    this.gravityScale = 1.0,
    this.hitboxScale = 1.0,
    this.coinAttraction = 1.0,
  });

  /// Damping applied to vertical velocity before a jump (smoother control).
  final double control;

  /// Reduces post-jump drift so taps feel more precise.
  final double jumpPrecision;

  /// Multiplier on gravity (lower = floatier).
  final double gravityScale;

  /// Multiplier on the collision hitbox (lower = more forgiving).
  final double hitboxScale;

  /// Multiplier on the coin attraction radius (higher = easier pickups).
  final double coinAttraction;

  CharacterStats improved({
    double? control,
    double? jumpPrecision,
    double? gravityScale,
    double? hitboxScale,
    double? coinAttraction,
  }) =>
      CharacterStats(
        control: control ?? this.control,
        jumpPrecision: jumpPrecision ?? this.jumpPrecision,
        gravityScale: gravityScale ?? this.gravityScale,
        hitboxScale: hitboxScale ?? this.hitboxScale,
        coinAttraction: coinAttraction ?? this.coinAttraction,
      );

  Map<String, double> toJson() => {
        'control': control,
        'jumpPrecision': jumpPrecision,
        'gravityScale': gravityScale,
        'hitboxScale': hitboxScale,
        'coinAttraction': coinAttraction,
      };
}

/// Visual-only gameplay tuning for an illustrated bird.
///
/// These values deliberately never participate in physics or collision. They
/// let the renderer normalize perceived silhouette size, wing tempo and glow
/// strength without scattering character-ID checks through Flame components.
@immutable
class CharacterGameplayVisual {
  const CharacterGameplayVisual({
    this.scale = 1.18,
    this.offset = Offset.zero,
    this.flapCycleDuration = 0.52,
    this.glowRadius = 0.15,
    this.glowOpacity = 0.34,
    this.innerGlowOpacity = 0.16,
    this.tapGlowBoost = 0.16,
  })  : assert(scale >= 0.9 && scale <= 1.3),
        assert(flapCycleDuration >= 0.36 && flapCycleDuration <= 0.72),
        assert(glowRadius >= 0.08 && glowRadius <= 0.24),
        assert(glowOpacity >= 0 && glowOpacity <= 0.55),
        assert(innerGlowOpacity >= 0 && innerGlowOpacity <= 0.35),
        assert(tapGlowBoost >= 0 && tapGlowBoost <= 0.3);

  /// Render-only scale centered on the existing torso-based component anchor.
  final double scale;

  /// Small visual alignment adjustment in logical player-canvas pixels.
  final Offset offset;

  /// Time for a complete up → mid → down → mid wing cycle in seconds.
  final double flapCycleDuration;

  /// Outer glow blur radius expressed as a fraction of the player canvas.
  final double glowRadius;

  /// Stable outer glow opacity for normal flight.
  final double glowOpacity;

  /// Tight accent layer that keeps energy cores and wing edges readable.
  final double innerGlowOpacity;

  /// Temporary opacity added after a tap without restarting the wing cycle.
  final double tapGlowBoost;
}

/// A playable neon character for the store.
@immutable
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.price,
    required this.isFree,
    required this.primary,
    required this.accent,
    required this.stats,
    required this.description,
    this.menuScale = 1.0,
    this.menuOffset = Offset.zero,
    this.shopScale = 1.0,
    this.shopOffset = Offset.zero,
    this.menuFrameScale = 0.68,
    this.menuArtworkScale = 0.98,
    this.shopFrameScale = 0.82,
    this.shopArtworkScale = 0.96,
    this.gameplayVisual = const CharacterGameplayVisual(),
  });

  final String id;
  final String name;
  final int price;
  final bool isFree;
  final Color primary;
  final Color accent;
  final CharacterStats stats;
  final String description;
  final double menuScale;
  final Offset menuOffset;
  final double shopScale;
  final Offset shopOffset;

  /// Centralized visual presentation metadata. These values preserve each
  /// artwork's natural silhouette without scattering character-ID checks
  /// throughout the menu and store widgets.
  final double menuFrameScale;
  final double menuArtworkScale;
  final double shopFrameScale;
  final double shopArtworkScale;

  /// Central gameplay presentation metadata. It affects only Flame rendering;
  /// movement, scoring and the torso collision radius remain unchanged.
  final CharacterGameplayVisual gameplayVisual;
}
