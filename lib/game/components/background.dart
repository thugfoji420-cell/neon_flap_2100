import 'dart:math';
import 'package:flutter/material.dart';

import 'package:flame/components.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/core/utils/neon_paint.dart';

// Cached paints reused every frame to avoid allocation in the render loop.
final _starPaint = Paint()..color = NeonPalette.white.withOpacity(0.7);

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

    // Sky gradient — the shader is recreated on resize but cached per call.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), _skyGradient(w, h));

    // Stars — paint cached at top of file.
    for (final s in _stars) {
      canvas.drawCircle(s, 1.2, _starPaint);
    }

    // Far skyline (slow parallax).
    _drawLayer(canvas, _far, _farScroll, 0.55);
    // Near skyline (faster parallax).
    _drawLayer(canvas, _near, _scroll, 0.85);
  }

  static final _skyGradientCache = <int, Shader>{};
  static Paint _skyGradient(double w, double h) {
    final key = w.toInt() << 16 | h.toInt();
    if (!_skyGradientCache.containsKey(key)) {
      const colors = [
        NeonPalette.backgroundDeep,
        NeonPalette.backgroundDark,
        Color(0xFF160a35),
      ];
      final grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      );
      _skyGradientCache[key] = grad.createShader(Rect.fromLTWH(0, 0, w, h));
    }
    return Paint()..shader = _skyGradientCache[key];
  }

  void _drawLayer(Canvas canvas, List<_Building> layer, double scroll, double alpha) {
    if (layer.isEmpty) return;
    final w = worldSize.x;
    final h = worldSize.y;
    final total = layer.last.x + layer.last.w + 80;
    final off = scroll % total;

    // Pre-allocated paints reused across all buildings in this call.
    // Only the .color field changes per building — opacity and mask are
    // set here once to avoid per-frame Paint() allocations.
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final win = Paint();

    for (int pass = 0; pass < 2; pass++) {
      final shift = pass == 0 ? -off : total - off;
      for (final b in layer) {
        final bx = b.x + shift;
        if (bx + b.w < -10 || bx > w + 10) continue;
        final top = h - b.h * alpha - 60;
        final rect = Rect.fromLTWH(bx, top, b.w, b.h);
        fill.color = b.color.withOpacity(0.10);
        canvas.drawRect(rect, fill);
        stroke.color = b.color.withOpacity(0.5);
        canvas.drawRect(rect, stroke);
        // A few lit windows.
        win.color = b.color.withOpacity(0.6);
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

    // Base bar — neonFill is reused, no allocation.
    canvas.drawRect(Rect.fromLTWH(0, top, w, height),
        neonFill(color, glow: 18, alpha: 0.18));
    canvas.drawLine(Offset(0, top), Offset(w, top), neonGlowStroke(color, 5, glow: 16));
    canvas.drawLine(Offset(0, top), Offset(w, top), neonStroke(color, 3));

    // Moving energy ticks — paints cached across calls.
    _tickGlow.color = color.withOpacity(0.55);
    _tick.color = color;
    _tick.strokeWidth = 2;
    _tickGlow.strokeWidth = 4;
    final spacing = 36.0;
    final off = _scroll % spacing;
    for (double x = -off; x < w; x += spacing) {
      canvas.drawLine(Offset(x, top + 8), Offset(x + 14, top + 8), _tickGlow);
      canvas.drawLine(Offset(x, top + 8), Offset(x + 14, top + 8), _tick);
    }
  }

  // Pre-allocated paints for ground ticks, avoiding paint construction every
  // frame (neonGlowStroke / neonStroke create new Paint objects each call).
  final Paint _tickGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  final Paint _tick = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
}
