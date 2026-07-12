import 'dart:math';
import 'package:flutter/material.dart';

import 'package:flame/components.dart';

import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/core/utils/neon_paint.dart';

/// Procedurally drawn cyberpunk city: gradient sky, twinkling stars, two
/// parallax skyline layers and a perspective grid floor. Scrolling offsets are
/// advanced by the game each frame so the world feels alive.
class CityBackground extends Component {
  CityBackground({required this.worldSize});

  final Vector2 worldSize;

  double _scroll = 0;
  double _farScroll = 0;
  final List<Offset> _stars = [];
  final List<_Building> _far = [];
  final List<_Building> _near = [];

  @override
  Future<void> onLoad() async {
    final rnd = Random(7);
    final w = worldSize.x;
    final h = worldSize.y;
    for (int i = 0; i < 70; i++) {
      _stars.add(Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.7));
    }
    double x = -50;
    while (x < w * 2.2) {
      final bw = 26 + rnd.nextDouble() * 46;
      final bh = 50 + rnd.nextDouble() * 170;
      _far.add(_Building(x, bw, bh, _pickColor(rnd)));
      x += bw + 8 + rnd.nextDouble() * 22;
    }
    x = -50;
    while (x < w * 2.2) {
      final bw = 34 + rnd.nextDouble() * 54;
      final bh = 80 + rnd.nextDouble() * 210;
      _near.add(_Building(x, bw, bh, _pickColor(rnd)));
      x += bw + 14 + rnd.nextDouble() * 30;
    }
    await super.onLoad();
  }

  static Color _pickColor(Random rnd) {
    const palette = [
      NeonPalette.cyan,
      NeonPalette.magenta,
      NeonPalette.purple,
      NeonPalette.green,
    ];
    return palette[rnd.nextInt(palette.length)];
  }

  /// Advance parallax based on world speed and delta time.
  void advance(double speed, double dt) {
    _scroll += speed * dt;
    _farScroll += speed * 0.45 * dt;
  }

  @override
  void render(Canvas canvas) {
    final w = worldSize.x;
    final h = worldSize.y;

    // Sky gradient.
    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        NeonPalette.backgroundDeep,
        NeonPalette.backgroundDark,
        const Color(0xFF160a35),
      ],
    );
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, w, h)));

    // Stars.
    final starPaint = Paint()..color = NeonPalette.white.withOpacity(0.7);
    for (final s in _stars) {
      canvas.drawCircle(s, 1.2, starPaint);
    }

    // Far skyline (slow parallax).
    _drawLayer(canvas, _far, _farScroll, 0.55);
    // Near skyline (faster parallax).
    _drawLayer(canvas, _near, _scroll, 0.85);
  }

  void _drawLayer(Canvas canvas, List<_Building> layer, double scroll, double alpha) {
    if (layer.isEmpty) return;
    final w = worldSize.x;
    final h = worldSize.y;
    final total = layer.last.x + layer.last.w + 80;
    final off = scroll % total;
    for (int pass = 0; pass < 2; pass++) {
      final shift = pass == 0 ? -off : total - off;
      for (final b in layer) {
        final bx = b.x + shift;
        if (bx + b.w < -10 || bx > w + 10) continue;
        final top = h - b.h * alpha - 60;
        final rect = Rect.fromLTWH(bx, top, b.w, b.h);
        final paint = Paint()
          ..color = b.color.withOpacity(0.10)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRect(rect, paint);
        final edge = Paint()
          ..color = b.color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRect(rect, edge);
        // A few lit windows.
        final win = Paint()..color = b.color.withOpacity(0.6);
        for (double wy = top + 10; wy < h - 70; wy += 16) {
          if (((wy + b.x) % 37) < 18) {
            canvas.drawRect(Rect.fromLTWH(bx + 6, wy, 4, 6), win);
          }
        }
      }
    }
  }
}

class _Building {
  _Building(this.x, this.w, this.h, this.color);
  final double x;
  final double w;
  final double h;
  final Color color;
}

/// The neon ground strip at the bottom of the play field.
class Ground extends Component {
  Ground({required this.worldSize, required this.height});
  final Vector2 worldSize;
  final double height;
  double _scroll = 0;
  final Color color = NeonPalette.cyan;

  void advance(double speed, double dt) => _scroll += speed * dt;

  @override
  void render(Canvas canvas) {
    final w = worldSize.x;
    final h = worldSize.y;
    final top = h - height;
    // Base bar.
    canvas.drawRect(Rect.fromLTWH(0, top, w, height),
        neonFill(color, glow: 18, alpha: 0.18));
    canvas.drawLine(Offset(0, top), Offset(w, top), neonGlowStroke(color, 5, glow: 16));
    canvas.drawLine(Offset(0, top), Offset(w, top), neonStroke(color, 3));
    // Moving energy ticks.
    final tickGlow = neonGlowStroke(color, 4, glow: 10);
    final tick = neonStroke(color, 2);
    final spacing = 36.0;
    final off = _scroll % spacing;
    for (double x = -off; x < w; x += spacing) {
      canvas.drawLine(Offset(x, top + 8), Offset(x + 14, top + 8), tickGlow);
      canvas.drawLine(Offset(x, top + 8), Offset(x + 14, top + 8), tick);
    }
  }
}
