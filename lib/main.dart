import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const FloppyBirdApp());
}

class FloppyBirdApp extends StatelessWidget {
  const FloppyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floppy Bird',
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade200,
      body: Center(
        child: FittedBox(
          child: SizedBox(
            width: 400,
            height: 600,
            child: GameBoard(),
          ),
        ),
      ),
    );
  }
}

// Game constants
const double gravity = 0.5;
const double jumpVelocity = -9;
const double birdSize = 30;
const double pipeWidth = 50;
const double pipeGap = 170;
const double pipeSpeed = 4;
const int pipeSpawnIntervalMs = 1600;
const double groundHeight = 70;
const double birdStartX = 100;

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with SingleTickerProviderStateMixin {
  late double birdY;
  double birdVelocity = 0;
  double birdRotation = 0;
  List<Pipe> pipes = [];
  int score = 0;
  bool isGameOver = false;
  bool hasStarted = false;
  late Timer pipeTimer;
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
    isGameOver = false;
    birdY = 250;
    birdVelocity = 0;
    score = 0;
    pipes.clear();
    pipeTimer.cancel();
    pipeTimer = Timer.periodic(Duration(milliseconds: pipeSpawnIntervalMs), (_) {
      if (!isGameOver) {
        pipes.add(Pipe.generate());
      }
    });
    // Spawn first pipe after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!isGameOver && mounted) {
        pipes.add(Pipe.generate());
      }
    });
  }

  void jump() {
    if (!hasStarted) {
      startGame();
    }
    if (!isGameOver) {
      birdVelocity = jumpVelocity;
    }
  }

  void resetGame() {
    isGameOver = false;
    hasStarted = false;
    birdY = 250;
    birdVelocity = 0;
    birdRotation = 0;
    pipes.clear();
    score = 0;
    pipeTimer.cancel();
    setState(() {});
  }

  void update() {
    // Apply gravity
    birdVelocity += gravity;
    birdY += birdVelocity;

    // Bird rotation based on velocity
    birdRotation = birdVelocity * 0.05;
    if (birdRotation > 0.8) birdRotation = 0.8;
    if (birdRotation < -0.8) birdRotation = -0.8;

    // Move pipes
    for (var pipe in pipes) {
      pipe.x -= pipeSpeed;
    }

    // Remove off-screen pipes
    pipes.removeWhere((pipe) => pipe.x < -pipeWidth);

    // Score check
    for (var pipe in pipes) {
      if (!pipe.scored && pipe.x + pipeWidth < birdStartX) {
        pipe.scored = true;
        score++;
      }
    }

    // Collision detection
    checkCollisions();
  }

  void checkCollisions() {
    // Ground collision
    if (birdY + birdSize / 2 > 600 - groundHeight) {
      gameOver();
      return;
    }

    // Ceiling collision
    if (birdY - birdSize / 2 < 0) {
      birdY = birdSize / 2;
      birdVelocity = 0;
    }

    // Pipe collisions
    for (var pipe in pipes) {
      // Check if bird overlaps pipe horizontally
      if (birdStartX + birdSize / 2 > pipe.x &&
          birdStartX - birdSize / 2 < pipe.x + pipeWidth) {
        // Top pipe collision
        if (birdY - birdSize / 2 < pipe.topHeight) {
          gameOver();
          return;
        }
        // Bottom pipe collision
        if (birdY + birdSize / 2 > pipe.topHeight + pipeGap) {
          gameOver();
          return;
        }
      }
    }
  }

  void gameOver() {
    isGameOver = true;
    pipeTimer.cancel();
    // If bird is above ground, let it fall to ground
    if (birdY + birdSize / 2 < 600 - groundHeight) {
      birdVelocity = gravity * 3;
    }
  }

  @override
  void dispose() {
    gameLoop.cancel();
    if (hasStarted) pipeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isGameOver) {
          resetGame();
        } else {
          jump();
        }
      },
      child: CustomPaint(
        size: const Size(400, 600),
        painter: GamePainter(
          birdY: birdY,
          birdRotation: birdRotation,
          pipes: pipes,
          score: score,
          isGameOver: isGameOver,
          hasStarted: hasStarted,
          frameCount: frameCount,
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

  static Pipe generate() {
    final random = Random();
    // Ensure top pipe is between 60 and 400 (leaving room for gap and ground)
    final topHeight = 60 + random.nextDouble() * 340;
    return Pipe(x: 400, topHeight: topHeight);
  }
}

class GamePainter extends CustomPainter {
  final double birdY;
  final double birdRotation;
  final List<Pipe> pipes;
  final int score;
  final bool isGameOver;
  final bool hasStarted;
  final int frameCount;

  GamePainter({
    required this.birdY,
    required this.birdRotation,
    required this.pipes,
    required this.score,
    required this.isGameOver,
    required this.hasStarted,
    required this.frameCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGround(canvas, size);
    _drawPipes(canvas, size);
    _drawBird(canvas, size);
    _drawScore(canvas, size);

    if (!hasStarted) {
      _drawStartMessage(canvas, size);
    }

    if (isGameOver) {
      _drawGameOver(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Sky gradient
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height - groundHeight);
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF4FC3F7),
        Color(0xFF81D4FA),
        Color(0xFFB3E5FC),
      ],
    );
    final paint = Paint()..shader = skyGradient.createShader(skyRect);
    canvas.drawRect(skyRect, paint);
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundPaint = Paint()..color = Color(0xFF8B4513);
    final grassPaint = Paint()..color = Color(0xFF4CAF50);

    // Grass top strip
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - groundHeight, size.width, 10),
      grassPaint,
    );

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - groundHeight + 10, size.width, groundHeight - 10),
      groundPaint,
    );

    // Ground pattern
    final linePaint = Paint()
      ..color = Color(0xFF6B3410)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      final offsetX = (frameCount * 2) % 40;
      canvas.drawLine(
        Offset(x - offsetX, size.height - groundHeight + 20),
        Offset(x - offsetX + 20, size.height - groundHeight + 60),
        linePaint,
      );
    }
  }

  void _drawPipes(Canvas canvas, Size size) {
    for (var pipe in pipes) {
      _drawSinglePipe(canvas, pipe, size);
    }
  }

  void _drawSinglePipe(Canvas canvas, Pipe pipe, Size size) {
    final pipeBodyPaint = Paint()..color = Color(0xFF4CAF50);
    final pipeBorderPaint = Paint()..color = Color(0xFF388E3C);
    final pipeHighlightPaint = Paint()..color = Color(0xFF66BB6A);

    // Top pipe body
    final topPipeRect = Rect.fromLTWH(pipe.x, 0, pipeWidth, pipe.topHeight);
    canvas.drawRect(topPipeRect, pipeBodyPaint);

    // Top pipe border
    canvas.drawRect(topPipeRect, pipeBorderPaint..style = PaintingStyle.stroke);

    // Top pipe highlight
    canvas.drawRect(
      Rect.fromLTWH(pipe.x + 5, 0, 10, pipe.topHeight),
      pipeHighlightPaint,
    );

    // Top pipe cap
    final topCapRect = Rect.fromLTWH(
      pipe.x - 5,
      pipe.topHeight - 30,
      pipeWidth + 10,
      30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topCapRect, const Radius.circular(5)),
      pipeBodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topCapRect, const Radius.circular(5)),
      pipeBorderPaint..style = PaintingStyle.stroke,
    );

    // Bottom pipe body
    final bottomPipeStart = pipe.topHeight + pipeGap;
    final bottomPipeRect = Rect.fromLTWH(
      pipe.x,
      bottomPipeStart,
      pipeWidth,
      size.height - bottomPipeStart - groundHeight,
    );
    canvas.drawRect(bottomPipeRect, pipeBodyPaint);

    // Bottom pipe border
    canvas.drawRect(bottomPipeRect, pipeBorderPaint..style = PaintingStyle.stroke);

    // Bottom pipe highlight
    canvas.drawRect(
      Rect.fromLTWH(pipe.x + 5, bottomPipeStart, 10, size.height - bottomPipeStart - groundHeight),
      pipeHighlightPaint,
    );

    // Bottom pipe cap
    final bottomCapRect = Rect.fromLTWH(
      pipe.x - 5,
      bottomPipeStart,
      pipeWidth + 10,
      30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bottomCapRect, const Radius.circular(5)),
      pipeBodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bottomCapRect, const Radius.circular(5)),
      pipeBorderPaint..style = PaintingStyle.stroke,
    );
  }

  void _drawBird(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(birdStartX, birdY);
    canvas.rotate(birdRotation);

    // Bird body
    final bodyPaint = Paint()..color = Color(0xFFFFEB3B);
    canvas.drawCircle(Offset.zero, birdSize / 2, bodyPaint);

    // Bird belly (lighter)
    final bellyPaint = Paint()..color = Color(0xFFFFF9C4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(2, 5), width: 20, height: 16),
      bellyPaint,
    );

    // Bird outline
    final outlinePaint = Paint()
      ..color = Color(0xFFF57F17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, birdSize / 2, outlinePaint);

    // Eye (white)
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(8, -5), 7, eyeWhitePaint);

    // Pupil
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(const Offset(10, -5), 4, pupilPaint);

    // Eye highlight
    final highlightPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(12, -7), 2, highlightPaint);

    // Beak
    final beakPaint = Paint()..color = Color(0xFFFF9800);
    final beakPath = Path()
      ..moveTo(15, 2)
      ..lineTo(28, 4)
      ..lineTo(15, 8)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // Wing
    final wingPaint = Paint()..color = Color(0xFFFDD835);
    final wingPath = Path()
      ..moveTo(-5, 5)
      ..quadraticBezierTo(-2, -5, -10, 0)
      ..quadraticBezierTo(-15, 8, -5, 12)
      ..close();
    canvas.drawPath(wingPath, wingPaint);

    // Wing animation (flap effect)
    if (!isGameOver) {
      final flapOffset = sin(frameCount * 0.3) * 2;
      final wingFlapPath = Path()
        ..moveTo(-5, 5 + flapOffset)
        ..quadraticBezierTo(-2, -5 + flapOffset, -10, 0 + flapOffset)
        ..quadraticBezierTo(-15, 8 + flapOffset, -5, 12 + flapOffset)
        ..close();
      canvas.drawPath(wingFlapPath, wingPaint);
    }

    canvas.restore();
  }

  void _drawScore(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 40));
  }

  void _drawStartMessage(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'Floppy Bird',
        style: TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(size.width / 2 - titlePainter.width / 2, 170),
    );

    // Tap to start message with bounce animation
    final bounce = sin(frameCount * 0.08) * 8;
    final startPainter = TextPainter(
      text: TextSpan(
        text: 'Tap to Start',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    startPainter.layout();
    startPainter.paint(
      canvas,
      Offset(size.width / 2 - startPainter.width / 2, 260 + bounce),
    );

    // Simple bird icon
    _drawSimpleBirdIcon(canvas, size, 350 + bounce);
  }

  void _drawSimpleBirdIcon(Canvas canvas, Size size, double y) {
    canvas.save();
    canvas.translate(200, y);

    final bodyPaint = Paint()..color = Color(0xFFFFEB3B);
    canvas.drawCircle(Offset.zero, 20, bodyPaint);

    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(const Offset(8, -5), 5, eyePaint);
    final highlightPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(10, -7), 2, highlightPaint);

    final beakPaint = Paint()..color = Color(0xFFFF9800);
    final beakPath = Path()
      ..moveTo(15, 2)
      ..lineTo(30, 4)
      ..lineTo(15, 10)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    canvas.restore();
  }

  void _drawGameOver(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Game Over panel
    final panelPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, 260), width: 280, height: 200),
      const Radius.circular(20),
    );
    canvas.drawRRect(panelRect, panelPaint);

    // Game Over text
    final gameOverPainter = TextPainter(
      text: TextSpan(
        text: 'Game Over',
        style: TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    gameOverPainter.layout();
    gameOverPainter.paint(
      canvas,
      Offset(size.width / 2 - gameOverPainter.width / 2, 200),
    );

    // Score
    final scorePainter = TextPainter(
      text: TextSpan(
        text: 'Score: $score',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 28,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(
      canvas,
      Offset(size.width / 2 - scorePainter.width / 2, 255),
    );

    // Restart button
    final buttonPaint = Paint()..color = Color(0xFF4CAF50);
    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, 320), width: 200, height: 50),
      const Radius.circular(25),
    );
    canvas.drawRRect(buttonRect, buttonPaint);

    final restartPainter = TextPainter(
      text: TextSpan(
        text: 'Tap to Restart',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
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