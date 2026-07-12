/// Cyberpunk neon colour palette shared across Flutter UI and the Flame game.
library;

import 'package:flutter/material.dart';

/// Neon colour palette for the whole game.
class NeonPalette {
  const NeonPalette._();

  static const Color backgroundDeep = Color(0xFF05010f);
  static const Color backgroundDark = Color(0xFF0a0420);
  static const Color surface = Color(0xFF120a2e);

  static const Color cyan = Color(0xFF00f0ff);
  static const Color magenta = Color(0xFFff2bd6);
  static const Color purple = Color(0xFF9d4dff);
  static const Color green = Color(0xFF39ff14);
  static const Color yellow = Color(0xFFffd000);
  static const Color red = Color(0xFFff3860);
  static const Color white = Color(0xFFeafcff);

  /// Glowing stroke colour per visual layer.
  static const List<Color> pipeCycle = [cyan, magenta, purple, green];
}

/// Pre-configured neon text styles. The game falls back to the platform font
/// for a consistent, dependency-free build.
class NeonTextStyle {
  const NeonTextStyle._();

  static const String fontFamily = 'Orbitron';

  static const title = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: 3,
    color: NeonPalette.white,
    shadows: [
      Shadow(color: NeonPalette.cyan, blurRadius: 18),
      Shadow(color: NeonPalette.magenta, blurRadius: 30),
    ],
  );

  static const heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: NeonPalette.white,
    shadows: [Shadow(color: NeonPalette.cyan, blurRadius: 12)],
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    color: NeonPalette.white,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: NeonPalette.cyan,
  );
}
