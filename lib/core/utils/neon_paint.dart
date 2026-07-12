import 'dart:math';

import 'package:flutter/material.dart';

/// Procedural neon rendering helpers. The game draws everything with the
/// canvas (no image assets) for a crisp, resolution-independent look.
///
/// Neon is drawn in two passes: a soft *blurred* halo underneath, and a
/// *crisp* (un-blurred) core line on top. Blurring the core line itself is
/// what made the whole game look out of focus, so the core is always sharp.

/// A crisp neon stroke (the bright, sharp core line drawn on top of the glow).
/// [glow] is accepted for call-site compatibility but the core stays sharp.
Paint neonStroke(Color color, double width, {double glow = 12}) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round;

/// A blurred stroke used as the glow halo behind a crisp line.
Paint neonGlowStroke(Color color, double width, {double glow = 12}) => Paint()
  ..color = color.withOpacity(0.55)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow);

/// A soft filled glow paint (halo).
Paint neonFill(Color color, {double glow = 16, double alpha = 1}) => Paint()
  ..color = color.withOpacity(alpha)
  ..style = PaintingStyle.fill
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow);

void drawNeonRoundedRect(
  Canvas canvas,
  Rect rect, {
  required Color color,
  double radius = 12,
  double strokeWidth = 4,
  double glow = 14,
  double fillAlpha = 0.18,
}) {
  final r = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  // Outer glow fill.
  canvas.drawRRect(r, neonFill(color, glow: glow, alpha: fillAlpha));
  // Blurred halo behind the edge.
  canvas.drawRRect(r, neonGlowStroke(color, strokeWidth + 2, glow: glow));
  // Crisp neon edge on top.
  canvas.drawRRect(r, neonStroke(color, strokeWidth));
}

void drawNeonCircle(
  Canvas canvas,
  Offset center,
  double radius, {
  required Color color,
  double strokeWidth = 4,
  double glow = 16,
  double fillAlpha = 0.2,
}) {
  // Outer glow fill.
  canvas.drawCircle(center, radius, neonFill(color, glow: glow, alpha: fillAlpha));
  // Blurred halo behind the edge.
  canvas.drawCircle(center, radius, neonGlowStroke(color, strokeWidth + 2, glow: glow));
  // Crisp neon edge on top.
  canvas.drawCircle(center, radius, neonStroke(color, strokeWidth));
}

/// A vertical neon gradient bar (used for pipes).
void drawNeonBar(
  Canvas canvas,
  Rect rect, {
  required Color color,
  double glow = 14,
}) {
  final gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      color.withOpacity(0.1),
      color.withOpacity(0.85),
      color.withOpacity(0.1),
    ],
  );
  // Soft body fill (kept subtle so the bar reads as a solid pipe).
  final paint = Paint()..shader = gradient.createShader(rect);
  canvas.drawRect(rect, paint);

  // Bright leading edges: blurred halo first, then crisp lines.
  final glowEdge = neonGlowStroke(color, 5, glow: glow);
  canvas.drawLine(rect.topLeft, rect.bottomLeft, glowEdge);
  canvas.drawLine(rect.topRight, rect.bottomRight, glowEdge);
  final edge = neonStroke(color, 3);
  canvas.drawLine(rect.topLeft, rect.bottomLeft, edge);
  canvas.drawLine(rect.topRight, rect.bottomRight, edge);
}

// ---------------------------------------------------------------------------
// Neon bird (the playable character shape)
// ---------------------------------------------------------------------------

/// A brighter rim colour (blended toward white) for a crisp filled edge.
Color _rim(Color color) => Color.lerp(color, const Color(0xFFFFFFFF), 0.45)!;

/// Draws a fully-filled neon shape: an outer glow halo, a solid opaque body,
/// a blurred edge halo and a bright crisp rim on top.
void _neonPathShape(
  Canvas canvas,
  Path path,
  Color color, {
  double glow = 14,
  double fillAlpha = 1.0,
  double stroke = 3,
}) {
  // Outer soft glow halo.
  canvas.drawPath(path, neonFill(color, glow: glow, alpha: 0.4));
  // Solid, fully-filled body.
  canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(fillAlpha)
        ..style = PaintingStyle.fill);
  // Blurred edge halo + bright crisp rim.
  canvas.drawPath(path, neonGlowStroke(color, stroke + 2, glow: glow));
  canvas.drawPath(path, neonStroke(_rim(color), stroke));
}

void _neonCircleShape(
  Canvas canvas,
  Offset center,
  double radius,
  Color color, {
  double glow = 14,
  double fillAlpha = 1.0,
  double stroke = 3,
}) {
  canvas.drawCircle(center, radius, neonFill(color, glow: glow, alpha: 0.4));
  canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(fillAlpha)
        ..style = PaintingStyle.fill);
  canvas.drawCircle(center, radius, neonGlowStroke(color, stroke + 2, glow: glow));
  canvas.drawCircle(center, radius, neonStroke(_rim(color), stroke));
}

/// Draws a stylised neon bird facing right, centred on [center] and sized to
/// fit within a box of side [s]. [wingPhase] animates the wing flap (radians),
/// [tilt] rotates the whole bird (e.g. to dive/rise with velocity). Shared by
/// the in-game player and the store preview so the shape stays consistent.
void drawNeonBird(
  Canvas canvas,
  Offset center,
  double s, {
  required Color primary,
  required Color accent,
  double wingPhase = 0,
  double tilt = 0,
  double glow = 14,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(tilt);

  // Soft aura.
  canvas.drawCircle(
      Offset.zero, s * 0.5, neonFill(primary, glow: glow * 1.6, alpha: 0.08));

  // Tail (back-left, forked).
  final tail = Path()
    ..moveTo(-s * 0.22, 0)
    ..lineTo(-s * 0.48, -s * 0.14)
    ..lineTo(-s * 0.38, 0)
    ..lineTo(-s * 0.48, s * 0.14)
    ..close();
  _neonPathShape(canvas, tail, accent,
      glow: glow * 0.8, fillAlpha: 1.0, stroke: s * 0.03);

  // Body (oval).
  final body = Path()
    ..addOval(Rect.fromCenter(
        center: Offset(-s * 0.02, s * 0.02),
        width: s * 0.66,
        height: s * 0.46));
  _neonPathShape(canvas, body, primary,
      glow: glow, fillAlpha: 1.0, stroke: s * 0.045);

  // Wing (animated flap).
  final wingAngle = sin(wingPhase) * 0.5 - 0.15;
  canvas.save();
  canvas.translate(-s * 0.02, -s * 0.02);
  canvas.rotate(wingAngle);
  final wing = Path()
    ..moveTo(0, 0)
    ..lineTo(-s * 0.24, -s * 0.32)
    ..lineTo(s * 0.16, -s * 0.05)
    ..close();
  _neonPathShape(canvas, wing, accent,
      glow: glow, fillAlpha: 1.0, stroke: s * 0.04);
  canvas.restore();

  // Head.
  final headC = Offset(s * 0.24, -s * 0.06);
  _neonCircleShape(canvas, headC, s * 0.16, primary,
      glow: glow, fillAlpha: 1.0, stroke: s * 0.045);

  // Beak (triangle pointing right).
  final beak = Path()
    ..moveTo(s * 0.37, -s * 0.07)
    ..lineTo(s * 0.53, -s * 0.02)
    ..lineTo(s * 0.37, s * 0.04)
    ..close();
  _neonPathShape(canvas, beak, const Color(0xFFFFD54A),
      glow: glow * 0.7, fillAlpha: 1.0, stroke: s * 0.03);

  // Eye.
  final eyeC = Offset(s * 0.28, -s * 0.10);
  canvas.drawCircle(eyeC, s * 0.06, neonGlowStroke(accent, s * 0.03, glow: glow * 0.6));
  canvas.drawCircle(eyeC, s * 0.05, Paint()..color = const Color(0xFFFFFFFF));
  canvas.drawCircle(eyeC, s * 0.022, Paint()..color = const Color(0xFF07131F));

  canvas.restore();
}

