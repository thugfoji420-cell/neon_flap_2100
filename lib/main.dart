import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const FloppyBirdApp());
}

enum Difficulty { easy, normal, hard }

class DifficultySettings {
  final double pipeSpeed;
  final double obstacleSpeed;
  final int pipeSpawnIntervalMs;
  final int obstacleSpawnIntervalMs;
  final double pipeGap;

  DifficultySettings({
    required this.pipeSpeed,
    required this.obstacleSpeed,
    required this.pipeSpawnIntervalMs,
    required this.obstacleSpawnIntervalMs,
    required this.pipeGap,
  });

  static DifficultySettings forDifficulty(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return DifficultySettings(
          pipeSpeed: 3,
          obstacleSpeed: 2,
          pipeSpawnIntervalMs: 2000,
          obstacleSpawnIntervalMs: 4000,
          pipeGap: 250,
        );
      case Difficulty.normal:
        return DifficultySettings(
          pipeSpeed: 4,
          obstacleSpeed: 4,
          pipeSpawnIntervalMs: 1600,
          obstacleSpawnIntervalMs: 3000,
          pipeGap: 200,
        );
      case Difficulty.hard:
        return DifficultySettings(
          pipeSpeed: 6,
          obstacleSpeed: 6,
          pipeSpawnIntervalMs: 1200,
          obstacleSpawnIntervalMs: 2000,
          pipeGap: 170,
        );
    }
  }
}

class FloppyBirdApp extends StatelessWidget {
  const FloppyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEON FLAP 2050',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const double gravity = 0.5;
  static const double jumpVelocity = -9;
  static const double birdSize = 30;
  static const double pipeWidth = 50;
  static const double groundHeight = 80;
  static const double birdStartX = 100;
  static const int maxObstacles = 3;

  late double birdY;
  double birdVelocity = 0;
  double birdRotation = 0;
  List<Pipe> pipes = [];
  List<ExtraObstacle> obstacles = [];
  List<Particle> particles = [];
  int score = 0;
  bool isGameOver = false;
  bool hasStarted = false;
  bool showDifficultySelector = true;
  Difficulty selectedDifficulty = Difficulty.normal;
  Timer? pipeTimer;
  Timer? obstacleTimer;
  late Timer gameLoop;
  int frameCount = 0;

  @override
  void initState() {
    super.initState();
    birdY = 250;
    startGameLoop();
  }

  void startGameLoop() {
    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (hasStarted && !isGameOver) {
        update();
      }
      frameCount++;
      setState(() {});
    });
  }

  void startGame() {
    hasStarted = true;
    showDifficultySelector = false;
    isGameOver = false;
    birdY = 250;
    birdVelocity = 0;
    birdRotation = 0;
    score = 0;
    particles.clear();

    pipeTimer?.cancel();
    obstacleTimer?.cancel();
    pipes.clear();
    obstacles.clear();

    final settings = DifficultySettings.forDifficulty(selectedDifficulty);

    pipeTimer = Timer.periodic(
      Duration(milliseconds: settings.pipeSpawnIntervalMs),
      (_) {
        if (!isGameOver && mounted) {
          pipes.add(Pipe.generate(settings.pipeGap));
        }
      },
    );

    obstacleTimer = Timer.periodic(
      Duration(milliseconds: settings.obstacleSpawnIntervalMs),
      (_) {
        if (!isGameOver && obstacles.length < maxObstacles && mounted) {
          obstacles.add(ExtraObstacle.generate());
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!isGameOver && mounted) {
        pipes.add(
          Pipe.generate(
            DifficultySettings.forDifficulty(selectedDifficulty).pipeGap,
          ),
        );
      }
    });
  }

  void jump() {
    if (!hasStarted && showDifficultySelector) {
      return;
    }
    if (!hasStarted) {
      startGame();
    }
    if (!isGameOver) {
      birdVelocity = jumpVelocity;
    }
  }

  void resetGame() {
    hasStarted = false;
    showDifficultySelector = true;
    isGameOver = false;
    birdY = 250;
    birdVelocity = 0;
    birdRotation = 0;
    score = 0;
    pipes.clear();
    obstacles.clear();
    particles.clear();
    pipeTimer?.cancel();
    obstacleTimer?.cancel();
    setState(() {});
  }

  void exitGame() {
    SystemNavigator.pop();
  }

  void selectDifficulty(Difficulty diff) {
    selectedDifficulty = diff;
    showDifficultySelector = false;
    isGameOver = false;
    birdY = 250;
    birdVelocity = 0;
    birdRotation = 0;
    score = 0;
    pipes.clear();
    obstacles.clear();
    particles.clear();
    hasStarted = true;

    final settings = DifficultySettings.forDifficulty(selectedDifficulty);

    pipeTimer = Timer.periodic(
      Duration(milliseconds: settings.pipeSpawnIntervalMs),
      (_) {
        if (!isGameOver && mounted) {
          pipes.add(Pipe.generate(settings.pipeGap));
        }
      },
    );

    obstacleTimer = Timer.periodic(
      Duration(milliseconds: settings.obstacleSpawnIntervalMs),
      (_) {
        if (!isGameOver && obstacles.length < maxObstacles && mounted) {
          obstacles.add(ExtraObstacle.generate());
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!isGameOver && mounted) {
        pipes.add(
          Pipe.generate(
            DifficultySettings.forDifficulty(selectedDifficulty).pipeGap,
          ),
        );
      }
    });

    setState(() {});
  }

  void addParticles(double x, double y) {
    for (int i = 0; i < 10; i++) {
      particles.add(Particle(x: x, y: y, frameCount: 0));
    }
  }

  void update() {
    final settings = DifficultySettings.forDifficulty(selectedDifficulty);

    birdVelocity += gravity;
    birdY += birdVelocity;

    birdRotation = birdVelocity * 0.05;
    if (birdRotation > 0.8) birdRotation = 0.8;
    if (birdRotation < -0.8) birdRotation = -0.8;

    for (var pipe in pipes) {
      pipe.x -= settings.pipeSpeed;
    }

    pipes.removeWhere((pipe) => pipe.x < -pipeWidth);

    for (var obs in obstacles) {
      obs.x -= settings.obstacleSpeed;
      obs.y = obs.baseY + sin(frameCount * obs.frequency) * obs.amplitude;
    }

    obstacles.removeWhere((obs) => obs.x < -obs.radius * 2);

    for (var particle in particles) {
      particle.update();
    }
    particles.removeWhere((p) => p.frameCount > 30);

    for (var pipe in pipes) {
      if (!pipe.scored && pipe.x + pipeWidth < birdStartX) {
        pipe.scored = true;
        score++;
        addParticles(pipe.x + pipeWidth, birdY);
      }
    }

    checkCollisions();
  }

  void checkCollisions() {
    final settings = DifficultySettings.forDifficulty(selectedDifficulty);

    if (birdY + birdSize / 2 > 600 - groundHeight) {
      gameOver();
      return;
    }

    if (birdY - birdSize / 2 < 0) {
      birdY = birdSize / 2;
      birdVelocity = 0;
    }

    for (var pipe in pipes) {
      if (birdStartX + birdSize / 2 > pipe.x &&
          birdStartX - birdSize / 2 < pipe.x + pipeWidth) {
        if (birdY - birdSize / 2 < pipe.topHeight) {
          gameOver();
          return;
        }
        if (birdY + birdSize / 2 > pipe.topHeight + settings.pipeGap) {
          gameOver();
          return;
        }
      }
    }

    for (var obs in obstacles) {
      final dx = (birdStartX) - obs.x;
      final dy = birdY - obs.y;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < (birdSize / 2 + obs.radius)) {
        gameOver();
        return;
      }
    }
  }

  void gameOver() {
    isGameOver = true;
    pipeTimer?.cancel();
    obstacleTimer?.cancel();
    if (birdY + birdSize / 2 < 600 - groundHeight) {
      birdVelocity = gravity * 3;
    }
    addParticles(birdStartX, birdY);
  }

  @override
  void dispose() {
    gameLoop.cancel();
    pipeTimer?.cancel();
    obstacleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: FittedBox(
          child: SizedBox(
            width: 400,
            height: 600,
            child: GestureDetector(
              onTapDown: (details) {
                final pos = details.localPosition;
                if (showDifficultySelector) {
                  if (pos.dx > 80 && pos.dx < 320) {
                    if (pos.dy > 260 && pos.dy < 320) {
                      selectDifficulty(Difficulty.easy);
                    } else if (pos.dy > 340 && pos.dy < 400) {
                      selectDifficulty(Difficulty.normal);
                    } else if (pos.dy > 420 && pos.dy < 480) {
                      selectDifficulty(Difficulty.hard);
                    } else if (pos.dy > 500 && pos.dy < 560) {
                      exitGame();
                    }
                  }
                }
              },
              onTap: () {
                if (isGameOver) {
                  resetGame();
                } else if (!showDifficultySelector) {
                  jump();
                }
              },
              child: CustomPaint(
                size: const Size(400, 600),
                painter: GamePainter(
                  birdY: birdY,
                  birdRotation: birdRotation,
                  pipes: pipes,
                  obstacles: obstacles,
                  particles: particles,
                  score: score,
                  isGameOver: isGameOver,
                  hasStarted: hasStarted,
                  frameCount: frameCount,
                  pipeGap:
                      DifficultySettings.forDifficulty(
                        selectedDifficulty,
                      ).pipeGap,
                  selectedDifficulty: selectedDifficulty,
                  showDifficultySelector: showDifficultySelector,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Pipe {
  double x;
  double topHeight;
  bool scored;

  Pipe({required this.x, required this.topHeight, this.scored = false});

  static Pipe generate(double pipeGap) {
    final random = Random();
    final minTopHeight = 80;
    final maxTopHeight = 420 - pipeGap;
    final topHeight =
        minTopHeight + random.nextDouble() * (maxTopHeight - minTopHeight);
    return Pipe(x: 400, topHeight: topHeight);
  }
}

class ExtraObstacle {
  double x;
  double y;
  double baseY;
  double radius;
  double frequency;
  double amplitude;

  ExtraObstacle({
    required this.x,
    required this.y,
    required this.baseY,
    this.radius = 15,
    this.frequency = 0.04,
    this.amplitude = 40,
  });

  static ExtraObstacle generate() {
    final random = Random();
    final baseY = 100 + random.nextDouble() * 350;
    final amp = 30 + random.nextDouble() * 50;
    final freq = 0.03 + random.nextDouble() * 0.04;
    return ExtraObstacle(
      x: 420,
      y: baseY,
      baseY: baseY,
      amplitude: amp,
      frequency: freq,
      radius: 14 + random.nextDouble() * 6,
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  int frameCount;
  Color color;

  Particle({required this.x, required this.y, required this.frameCount})
    : vx = (Random().nextDouble() - 0.5) * 4,
      vy = (Random().nextDouble() - 0.5) * 4,
      color = Color(0xFF00FFFF + Random().nextInt(0xFF00FFFF));

  void update() {
    frameCount++;
    x += vx;
    y += vy;
    vx *= 0.95;
    vy *= 0.95;
  }
}

class GamePainter extends CustomPainter {
  final double birdY;
  final double birdRotation;
  final List<Pipe> pipes;
  final List<ExtraObstacle> obstacles;
  final List<Particle> particles;
  final int score;
  final bool isGameOver;
  final bool hasStarted;
  final int frameCount;
  final double pipeGap;
  final Difficulty selectedDifficulty;
  final bool showDifficultySelector;

  GamePainter({
    required this.birdY,
    required this.birdRotation,
    required this.pipes,
    required this.obstacles,
    required this.particles,
    required this.score,
    required this.isGameOver,
    required this.hasStarted,
    required this.frameCount,
    required this.pipeGap,
    required this.selectedDifficulty,
    required this.showDifficultySelector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawParticles(canvas, size);
    _drawGrid(canvas, size);
    _drawGround(canvas, size);
    _drawPipes(canvas, size);
    _drawObstacles(canvas, size);
    _drawBird(canvas, size);
    _drawScore(canvas, size);

    if (showDifficultySelector) {
      _drawDifficultySelector(canvas, size);
    } else if (!hasStarted) {
      _drawStartMessage(canvas, size);
    }

    if (isGameOver) {
      _drawGameOver(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A0A2A), Color(0xFF1A0A3A), Color(0xFF0A0A2A)],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = Color(0xFF00FFFF).withValues(alpha: 0.1)
          ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 30) {
      final offset = (frameCount * 0.5) % 30;
      for (double x = -offset; x < size.width; x += 30) {
        canvas.drawCircle(Offset(x + 15, y + 15), 2, gridPaint);
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint =
          Paint()
            ..color = p.color.withValues(alpha: 1 - p.frameCount / 30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(p.x, p.y), 3 + Random().nextDouble() * 2, paint);
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundPaint = Paint()..color = Color(0xFF003366);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 80, size.width, 80),
      groundPaint,
    );

    final gridPaint =
        Paint()
          ..color = Color(0xFF00FFFF)
          ..strokeWidth = 2;

    for (double x = 0; x < size.width; x += 40) {
      final offset = (frameCount * 2) % 40;
      canvas.drawLine(
        Offset(x - offset, size.height - 40),
        Offset(x - offset + 20, size.height - 10),
        gridPaint,
      );
    }

    final glowPaint =
        Paint()
          ..color = Color(0xFF00FFFF).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 82, size.width, 5),
      glowPaint,
    );
  }

  void _drawPipes(Canvas canvas, Size size) {
    for (var pipe in pipes) {
      _drawSinglePipe(canvas, pipe, size);
    }
  }

  void _drawSinglePipe(Canvas canvas, Pipe pipe, Size size) {
    final glowPaint =
        Paint()
          ..color = Color(0xFF00FFFF).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final pipeBodyPaint = Paint()..color = Color(0xFF0088FF);
    final pipeBorderPaint =
        Paint()
          ..color = Color(0xFF00FFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final highlightPaint = Paint()..color = Color(0xFF44CCFF);

    final topPipeRect = Rect.fromLTWH(pipe.x, 0, 50, pipe.topHeight);
    canvas.drawRect(topPipeRect, glowPaint);
    canvas.drawRect(topPipeRect, pipeBodyPaint);
    canvas.drawRect(topPipeRect, pipeBorderPaint);
    canvas.drawRect(
      Rect.fromLTWH(pipe.x + 5, 0, 10, pipe.topHeight),
      highlightPaint,
    );

    final topCapRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pipe.x - 5, pipe.topHeight - 25, 60, 25),
      const Radius.circular(5),
    );
    canvas.drawRRect(topCapRect, pipeBodyPaint);
    canvas.drawRRect(topCapRect, pipeBorderPaint);

    final bottomPipeStart = pipe.topHeight + pipeGap;
    final bottomPipeRect = Rect.fromLTWH(
      pipe.x,
      bottomPipeStart,
      50,
      size.height - bottomPipeStart - 80,
    );
    canvas.drawRect(bottomPipeRect, glowPaint);
    canvas.drawRect(bottomPipeRect, pipeBodyPaint);
    canvas.drawRect(bottomPipeRect, pipeBorderPaint);
    canvas.drawRect(
      Rect.fromLTWH(
        pipe.x + 5,
        bottomPipeStart,
        10,
        size.height - bottomPipeStart - 80,
      ),
      highlightPaint,
    );

    final bottomCapRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pipe.x - 5, bottomPipeStart, 60, 25),
      const Radius.circular(5),
    );
    canvas.drawRRect(bottomCapRect, pipeBodyPaint);
    canvas.drawRRect(bottomCapRect, pipeBorderPaint);
  }

  void _drawObstacles(Canvas canvas, Size size) {
    for (var obs in obstacles) {
      _drawSingleObstacle(canvas, obs, size);
    }
  }

  void _drawSingleObstacle(Canvas canvas, ExtraObstacle obs, Size size) {
    final rotationAngle = frameCount * 0.15;

    canvas.save();
    canvas.translate(obs.x, obs.y);
    canvas.rotate(rotationAngle);

    final glowPaint =
        Paint()
          ..color = Color(0xFFFF00FF).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, obs.radius + 4, glowPaint);

    final outerPaint = Paint()..color = Color(0xFFFF00FF);
    canvas.drawCircle(Offset.zero, obs.radius, outerPaint);

    final innerPaint = Paint()..color = Color(0xFFAA00AA);
    canvas.drawCircle(Offset.zero, obs.radius * 0.6, innerPaint);

    final spikePaint =
        Paint()
          ..color = Color(0xFFFF66FF)
          ..style = PaintingStyle.fill;
    final spikeBorderPaint =
        Paint()
          ..color = Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * pi / 8) + rotationAngle;
      final spikeLength = obs.radius * 0.5;
      final baseRadius = obs.radius * 0.75;

      final path = Path();
      path.moveTo(cos(angle - 0.2) * baseRadius, sin(angle - 0.2) * baseRadius);
      path.lineTo(
        cos(angle) * (obs.radius + spikeLength),
        sin(angle) * (obs.radius + spikeLength),
      );
      path.lineTo(cos(angle + 0.2) * baseRadius, sin(angle + 0.2) * baseRadius);
      path.close();

      canvas.drawPath(path, spikePaint);
      canvas.drawPath(path, spikeBorderPaint);
    }

    canvas.restore();
  }

  void _drawBird(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(100, birdY);
    canvas.rotate(birdRotation);

    final glowPaint =
        Paint()
          ..color = Color(0xFFFF00FF).withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, 18, glowPaint);

    final bodyPaint = Paint()..color = Color(0xFFFF00FF);
    canvas.drawCircle(Offset.zero, 15, bodyPaint);

    final energyPaint =
        Paint()
          ..color = Color(0xFFFFFF00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, 15, energyPaint);

    final wingPaint = Paint()..color = Color(0xFFAA00AA);
    if (!isGameOver) {
      final flapOffset = sin(frameCount * 0.3) * 3;
      final wingPath =
          Path()
            ..moveTo(-6, 6 + flapOffset)
            ..quadraticBezierTo(-2, -6 + flapOffset, -12, 0 + flapOffset)
            ..quadraticBezierTo(-18, 8 + flapOffset, -6, 14 + flapOffset)
            ..close();
      canvas.drawPath(wingPath, wingPaint);
    }

    final eyePaint = Paint()..color = Color(0xFFFFFFFF);
    canvas.drawCircle(const Offset(6, -3), 5, eyePaint);

    final pupilPaint = Paint()..color = Color(0xFF000000);
    canvas.drawCircle(const Offset(8, -3), 3, pupilPaint);

    final linePaint =
        Paint()
          ..color = Color(0xFF00FFFF)
          ..strokeWidth = 2;
    canvas.drawLine(const Offset(-2, 5), Offset(12, 5), linePaint);

    canvas.restore();
  }

  void _drawScore(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF00FFFF), blurRadius: 15)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, 30),
    );
  }

  void _drawDifficultySelector(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'NEON FLAP 2050',
        style: TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: 38,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 20)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(size.width / 2 - titlePainter.width / 2, 100),
    );

    _drawDifficultyButton(
      canvas,
      size,
      'CYBER EGG',
      260,
      Color(0xFF00FF00),
      selectedDifficulty == Difficulty.easy,
    );
    _drawDifficultyButton(
      canvas,
      size,
      'NEON PILOT',
      340,
      Color(0xFF00AAFF),
      selectedDifficulty == Difficulty.normal,
    );
    _drawDifficultyButton(
      canvas,
      size,
      'QUANTUM X',
      420,
      Color(0xFFFF0066),
      selectedDifficulty == Difficulty.hard,
    );
    _drawExitButtonInMenu(canvas, size);
  }

  void _drawDifficultyButton(
    Canvas canvas,
    Size size,
    String text,
    double y,
    Color color,
    bool selected,
  ) {
    final buttonPaint = Paint()..color = color.withValues(alpha: 0.3);
    final borderPaint =
        Paint()
          ..color = selected ? Color(0xFFFFFFFF) : Color(0xFF444444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 3 : 2;

    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, y),
        width: 240,
        height: 60,
      ),
      const Radius.circular(30),
    );
    canvas.drawRRect(buttonRect, buttonPaint);
    canvas.drawRRect(buttonRect, borderPaint);

    if (selected) {
      final glowPaint =
          Paint()
            ..color = color.withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(buttonRect, glowPaint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, y - 12),
    );
  }

  void _drawExitButtonInMenu(Canvas canvas, Size size) {
    _drawDifficultyButton(
      canvas,
      size,
      'EXIT GAME',
      530,
      Color(0xFFFF0066),
      false,
    );
  }

  void _drawStartMessage(Canvas canvas, Size size) {
    final bounce = sin(frameCount * 0.08) * 5;
    final tapPainter = TextPainter(
      text: TextSpan(
        text: 'JUMP',
        style: TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 15)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tapPainter.layout();
    tapPainter.paint(
      canvas,
      Offset(size.width / 2 - tapPainter.width / 2, 300 + bounce),
    );
  }

  void _drawGameOver(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    final panelPaint = Paint()..color = Color(0xFF1A1A2A);
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, 280),
        width: 280,
        height: 200,
      ),
      const Radius.circular(15),
    );
    canvas.drawRRect(panelRect, panelPaint);

    final panelGlow =
        Paint()
          ..color = Color(0xFFFF0066).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(panelRect, panelGlow);

    final gameOverPainter = TextPainter(
      text: TextSpan(
        text: 'GAME OVER',
        style: TextStyle(
          color: Color(0xFFFF0066),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF0066), blurRadius: 15)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    gameOverPainter.layout();
    gameOverPainter.paint(
      canvas,
      Offset(size.width / 2 - gameOverPainter.width / 2, 210),
    );

    final scorePainter = TextPainter(
      text: TextSpan(
        text: 'SCORE: $score',
        style: TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(
      canvas,
      Offset(size.width / 2 - scorePainter.width / 2, 250),
    );

    final buttonPaint =
        Paint()..color = Color(0xFFFF0066).withValues(alpha: 0.4);
    final borderPaint =
        Paint()
          ..color = Color(0xFFFF0066)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, 320),
        width: 200,
        height: 45,
      ),
      const Radius.circular(22),
    );
    canvas.drawRRect(buttonRect, borderPaint);
    canvas.drawRRect(buttonRect, buttonPaint);

    final restartPainter = TextPainter(
      text: TextSpan(
        text: 'RESTART',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    restartPainter.layout();
    restartPainter.paint(
      canvas,
      Offset(size.width / 2 - restartPainter.width / 2, 305),
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}
