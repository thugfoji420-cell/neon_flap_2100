import 'package:flutter/foundation.dart';
import 'dart:ui';
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
  });

  final String id;
  final String name;
  final int price;
  final bool isFree;
  final Color primary;
  final Color accent;
  final CharacterStats stats;
  final String description;
}
