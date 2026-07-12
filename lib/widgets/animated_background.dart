import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/theme/app_theme.dart';

/// Animated cyberpunk backdrop: a drifting perspective grid plus a slow pulse
/// of neon colour. Reused by every menu for a cohesive premium feel.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, this.accent = NeonPalette.cyan, this.child});

  final Color accent;
  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                widget.accent.withOpacity(0.10),
                NeonPalette.backgroundDeep,
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(_ctrl.value, widget.accent),
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.t, this.accent);
  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.42;
    final paint = Paint()
      ..color = accent.withOpacity(0.18)
      ..strokeWidth = 1;

    // Vertical converging lines.
    const cols = 14;
    for (var i = 0; i <= cols; i++) {
      final x = (i / cols) * size.width;
      canvas.drawLine(
        Offset(size.width / 2, horizon),
        Offset(x, size.height),
        paint,
      );
    }
    // Horizontal lines scrolling toward the viewer.
    const rows = 12;
    for (var i = 0; i < rows; i++) {
      final p = ((i / rows) + t) % 1;
      final y = horizon + p * p * (size.height - horizon);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.t != t;
}
