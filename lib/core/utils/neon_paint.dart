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
  canvas.drawCircle(
      center, radius, neonFill(color, glow: glow, alpha: fillAlpha));
  // Blurred halo behind the edge.
  canvas.drawCircle(
      center, radius, neonGlowStroke(color, strokeWidth + 2, glow: glow));
  // Crisp neon edge on top.
  canvas.drawCircle(center, radius, neonStroke(color, strokeWidth));
}

/// A vertical neon gradient bar (used for pipes).
void drawNeonBar(
  Canvas canvas,
  Rect rect, {
  required Color color,
  double glow = 14,
  double phase = 0,
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

  // A low-contrast animated energy scan gives every moving pipe a clear sense
  // of forward motion without obscuring its collision silhouette.
  final scanPaint = Paint()
    ..color = _rim(color).withOpacity(0.18)
    ..strokeWidth = 1;
  final scanStep = max(16.0, rect.width * 0.30);
  final scanOffset = (phase % 1) * scanStep;
  canvas.save();
  canvas.clipRect(rect);
  for (var y = rect.top - scanStep + scanOffset;
      y < rect.bottom;
      y += scanStep) {
    canvas.drawLine(
      Offset(rect.left + 3, y),
      Offset(rect.right - 3, y),
      scanPaint,
    );
  }
  canvas.restore();
}

// ---------------------------------------------------------------------------
// Neon bird (the playable character shape)
// ---------------------------------------------------------------------------

/// A brighter rim colour (blended toward white) for a crisp filled edge.
Color _rim(Color color) => Color.lerp(color, const Color(0xFFFFFFFF), 0.45)!;

double _variantValue(String id, int salt) {
  var hash = 0x811C9DC5 ^ salt;
  for (final codeUnit in id.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return (hash % 1000) / 999.0;
}

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

/// A layered radial gradient gives the bird body a dimensional metallic shell
/// while preserving the crisp neon rim used everywhere else in the game.
void _neonDimensionalPathShape(
  Canvas canvas,
  Path path,
  Color color, {
  required Color highlight,
  double glow = 14,
  double fillAlpha = 1.0,
  double stroke = 3,
}) {
  final bounds = path.getBounds();
  canvas.drawPath(path, neonFill(color, glow: glow, alpha: 0.42));
  final shell = Paint()
    ..style = PaintingStyle.fill
    ..shader = RadialGradient(
      center: const Alignment(-0.36, -0.48),
      radius: 1.18,
      colors: [
        Color.lerp(highlight, const Color(0xFFFFFFFF), 0.22)!
            .withOpacity(fillAlpha),
        color.withOpacity(fillAlpha),
        Color.lerp(color, const Color(0xFF050A18), 0.58)!
            .withOpacity(fillAlpha),
      ],
      stops: const [0, 0.46, 1],
    ).createShader(bounds.inflate(max(bounds.width, bounds.height) * 0.12));
  canvas.drawPath(path, shell);
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
  canvas.drawCircle(
      center, radius, neonGlowStroke(color, stroke + 2, glow: glow));
  canvas.drawCircle(center, radius, neonStroke(_rim(color), stroke));
}

/// Draws a dimensional neon bird facing right, centred on
/// [center] and sized to fit within a box of side [s]. [wingPhase] animates the
/// rotor/wing flap (radians) and [tilt] rotates the whole craft (e.g. to
/// dive/rise with velocity). The anchor, centre and size semantics are identical
/// to the previous bird so collision (based on [size]) and all call-sites stay
/// unchanged. Shared by the in-game player and the store preview so every skin
/// keeps a consistent futuristic style.
void drawNeonBird(
  Canvas canvas,
  Offset center,
  double s, {
  required Color primary,
  required Color accent,
  String variantId = 'nova',
  double wingPhase = 0,
  double tilt = 0,
  double glow = 14,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(tilt);
  canvas.translate(0, sin(wingPhase * 0.5) * s * 0.014);

  final wingVariant = _variantValue(variantId, 13);
  final tailVariant = _variantValue(variantId, 29);
  final beakVariant = _variantValue(variantId, 47);
  final armorVariant = _variantValue(variantId, 61);
  final flap = sin(wingPhase);
  final wingLift = -0.15 - flap * 0.34;
  final rearWingLift = 0.08 + flap * 0.20;
  final wingReach = 0.34 + wingVariant * 0.10;
  final tailReach = 0.30 + tailVariant * 0.12;
  final beakReach = 0.16 + beakVariant * 0.08;
  final tailFlutter = sin(wingPhase * 1.35 + tailVariant * pi) * s * 0.026;

  // Wide ambient aura.
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: s * 0.92, height: s * 0.66),
    neonFill(primary, glow: glow * 1.7, alpha: 0.10),
  );

  // Tail feathers: separate armored plumes, behind the body.
  for (var i = 0; i < 3; i++) {
    final y = (i - 1) * s * (0.08 + tailVariant * 0.03) + tailFlutter;
    final feather = Path()
      ..moveTo(-s * 0.28, y)
      ..quadraticBezierTo(
        -s * (0.44 + tailReach * 0.22),
        y - s * (0.15 - i * 0.05),
        -s * (0.50 + tailReach * 0.18),
        y + s * (i - 1) * 0.03,
      )
      ..quadraticBezierTo(
        -s * (0.42 + tailReach * 0.12),
        y + s * (0.12 - i * 0.04),
        -s * 0.18,
        y + s * 0.04,
      )
      ..close();
    _neonPathShape(
      canvas,
      feather,
      Color.lerp(accent, primary, i * 0.18)!,
      glow: glow * 0.7,
      fillAlpha: 0.88,
      stroke: s * 0.018,
    );
  }

  // Far wing behind the body, visible enough to read as a flying bird rather
  // than a static icon. Its opposite phase gives a natural flap cycle.
  canvas.save();
  canvas.translate(-s * 0.09, s * 0.05);
  canvas.rotate(rearWingLift);
  final rearWing = Path()
    ..moveTo(s * 0.05, -s * 0.02)
    ..cubicTo(-s * 0.10, s * 0.20, -s * (0.30 + wingVariant * 0.10), s * 0.26,
        -s * 0.42, s * 0.10)
    ..quadraticBezierTo(-s * 0.22, s * 0.03, s * 0.05, -s * 0.02)
    ..close();
  _neonPathShape(
    canvas,
    rearWing,
    Color.lerp(primary, accent, 0.40)!,
    glow: glow * 0.65,
    fillAlpha: 0.58,
    stroke: s * 0.018,
  );
  canvas.restore();

  // Main bird body: a rounded breast, tapered back and lit neck. A radial
  // shell gradient creates a 3D model-style volume without pixelated sprites.
  final body = Path()
    ..moveTo(s * 0.30, -s * 0.04)
    ..cubicTo(s * 0.20, -s * 0.24, -s * 0.08, -s * 0.28, -s * 0.30, -s * 0.10)
    ..cubicTo(-s * 0.42, s * 0.02, -s * 0.34, s * 0.24, -s * 0.08, s * 0.28)
    ..cubicTo(s * 0.18, s * 0.30, s * 0.38, s * 0.14, s * 0.30, -s * 0.04)
    ..close();
  _neonDimensionalPathShape(
    canvas,
    body,
    primary,
    highlight: accent,
    glow: glow,
    fillAlpha: 0.96,
    stroke: s * 0.035,
  );

  // Chest plates, energy veins and a small specular highlight make the body
  // read as a living cyber-bird rather than a flat drone icon.
  final bodyHighlight = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFFFFFFF).withOpacity(0.42),
        const Color(0xFFFFFFFF).withOpacity(0),
      ],
    ).createShader(Rect.fromLTWH(-s * 0.26, -s * 0.24, s * 0.38, s * 0.25));
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(-s * 0.06, -s * 0.12),
      width: s * 0.25,
      height: s * 0.10,
    ),
    bodyHighlight,
  );
  for (var i = 0; i < 4; i++) {
    final t = i / 3;
    final x = -s * 0.18 + t * s * 0.36;
    final plate = Path()
      ..moveTo(x - s * 0.08, -s * (0.10 - armorVariant * 0.03))
      ..quadraticBezierTo(x, -s * 0.02, x + s * 0.10, -s * 0.06)
      ..quadraticBezierTo(x + s * 0.04, s * 0.08, x - s * 0.08, s * 0.12);
    canvas.drawPath(
      plate,
      neonStroke(accent.withOpacity(0.72), s * 0.008, glow: glow * 0.45),
    );
  }
  _neonCircleShape(
    canvas,
    Offset(-s * 0.02, s * 0.02),
    s * 0.055,
    accent,
    glow: glow * 0.85,
    fillAlpha: 0.92,
    stroke: s * 0.014,
  );

  // Animated foreground wing: feathered, articulated and readable in both the
  // shop avatar and active gameplay.
  canvas.save();
  canvas.translate(-s * 0.04, -s * 0.03);
  canvas.rotate(wingLift);
  final wing = Path()
    ..moveTo(s * 0.08, 0)
    ..cubicTo(
        -s * 0.04,
        -s * (0.34 + flap.abs() * 0.05),
        -s * wingReach,
        -s * (0.42 + flap.abs() * 0.08),
        -s * 0.46,
        -s * (0.15 + wingVariant * 0.07))
    ..quadraticBezierTo(-s * 0.28, -s * 0.02, -s * 0.02, s * 0.13)
    ..quadraticBezierTo(s * 0.10, s * 0.08, s * 0.08, 0)
    ..close();
  _neonDimensionalPathShape(
    canvas,
    wing,
    accent,
    highlight: primary,
    glow: glow * 0.9,
    fillAlpha: 0.78,
    stroke: s * 0.026,
  );
  for (var i = 0; i < 5; i++) {
    final t = i / 4;
    final featherDrop = sin(wingPhase + t * pi) * s * 0.018;
    canvas.drawLine(
      Offset(-s * 0.02, -s * 0.01),
      Offset(
        -s * (0.12 + t * (wingReach + 0.16)),
        -s * (0.08 + t * (0.20 + wingVariant * 0.08)) + featherDrop,
      ),
      neonStroke(primary.withOpacity(0.7), s * 0.007, glow: glow * 0.35),
    );
  }
  for (var i = 0; i < 4; i++) {
    final t = i / 3;
    final tip = Path()
      ..moveTo(-s * (0.18 + t * 0.10), -s * (0.04 + t * 0.07))
      ..quadraticBezierTo(
        -s * (0.26 + t * 0.10),
        -s * (0.12 + t * 0.09) + sin(wingPhase + i) * s * 0.012,
        -s * (0.32 + t * 0.11),
        -s * (0.06 + t * 0.05),
      );
    canvas.drawPath(
      tip,
      neonStroke(accent.withOpacity(0.72), s * 0.006, glow: glow * 0.25),
    );
  }
  // Wing bones add a subtle perspective cue as the flap rotates.
  for (var i = 0; i < 3; i++) {
    final t = (i + 1) / 4;
    canvas.drawLine(
      Offset(-s * 0.02, s * 0.01),
      Offset(-s * (0.15 + t * wingReach), -s * (0.04 + t * 0.29)),
      neonStroke(_rim(primary).withOpacity(0.38), s * 0.006),
    );
  }
  canvas.restore();

  // Head and neck.
  final neck = Path()
    ..moveTo(s * 0.18, -s * 0.10)
    ..quadraticBezierTo(s * 0.26, -s * 0.28, s * 0.42, -s * 0.20)
    ..quadraticBezierTo(s * 0.34, -s * 0.06, s * 0.20, -s * 0.02)
    ..close();
  _neonDimensionalPathShape(
    canvas,
    neck,
    Color.lerp(primary, accent, 0.18)!,
    highlight: accent,
    glow: glow * 0.8,
    fillAlpha: 0.96,
    stroke: s * 0.024,
  );
  final headC = Offset(s * 0.38, -s * 0.20);
  final headPath = Path()
    ..addOval(Rect.fromCircle(center: headC, radius: s * 0.14));
  _neonDimensionalPathShape(
    canvas,
    headPath,
    primary,
    highlight: accent,
    glow: glow * 0.8,
    fillAlpha: 0.98,
    stroke: s * 0.028,
  );

  // Beak: clear bird silhouette, with an energized lower edge.
  final beak = Path()
    ..moveTo(s * 0.49, -s * 0.22)
    ..lineTo(s * (0.60 + beakReach), -s * 0.17)
    ..lineTo(s * 0.49, -s * 0.11)
    ..quadraticBezierTo(s * 0.53, -s * 0.17, s * 0.49, -s * 0.22)
    ..close();
  _neonPathShape(
    canvas,
    beak,
    const Color(0xFFFFD54A),
    glow: glow * 0.55,
    fillAlpha: 0.96,
    stroke: s * 0.018,
  );

  // Crest feather / cyber antenna, varied by character id.
  final crest = Path()
    ..moveTo(s * 0.32, -s * 0.32)
    ..quadraticBezierTo(
      s * (0.25 - armorVariant * 0.08),
      -s * (0.46 + wingVariant * 0.06),
      s * 0.42,
      -s * 0.34,
    );
  canvas.drawPath(
    crest,
    neonStroke(accent.withOpacity(0.88), s * 0.016, glow: glow * 0.5),
  );

  // Cybernetic eye.
  final eyeC = Offset(s * 0.42, -s * 0.23);
  canvas.drawCircle(
    eyeC,
    s * 0.055,
    neonGlowStroke(accent, s * 0.022, glow: glow * 0.55),
  );
  canvas.drawCircle(eyeC, s * 0.042, Paint()..color = const Color(0xFFFFFFFF));
  canvas.drawCircle(eyeC, s * 0.020, Paint()..color = const Color(0xFF07131F));
  canvas.drawCircle(
    eyeC.translate(s * 0.006, -s * 0.006),
    s * 0.008,
    Paint()..color = accent,
  );

  // A compact ion trail visually links the body to the animated tail while
  // making gliding and flap timing feel more alive in flight.
  final trailLength = s * (0.10 + (1 + flap) * 0.055);
  canvas.drawLine(
    Offset(-s * 0.30, s * 0.04),
    Offset(-s * 0.30 - trailLength, s * 0.04 + tailFlutter * 0.35),
    neonGlowStroke(accent, s * 0.028, glow: glow * 0.9),
  );
  canvas.drawLine(
    Offset(-s * 0.30, s * 0.04),
    Offset(-s * 0.30 - trailLength, s * 0.04 + tailFlutter * 0.35),
    neonStroke(_rim(accent), s * 0.009),
  );

  canvas.restore();
}
