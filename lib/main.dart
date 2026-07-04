import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FloppyBirdApp());
}

enum Difficulty { easy, normal, hard }

class DifficultySettings {
  final double pipeSpeed;
  final double obstacleSpeed;
  final int pipeSpawnIntervalMs;
  final int obstacleSpawnIntervalMs;
  final double pipeGap;
  final int maxObstacles;

  DifficultySettings({
    required this.pipeSpeed,
    required this.obstacleSpeed,
    required this.pipeSpawnIntervalMs,
    required this.obstacleSpawnIntervalMs,
    required this.pipeGap,
    required this.maxObstacles,
  });

  static DifficultySettings forDifficulty(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return DifficultySettings(
          pipeSpeed: 3,
          obstacleSpeed: 2,
          pipeSpawnIntervalMs: 1500,
          obstacleSpawnIntervalMs: 4000,
          pipeGap: 300,
          maxObstacles: 0,
        );
      case Difficulty.normal:
        return DifficultySettings(
          pipeSpeed: 4,
          obstacleSpeed: 4,
          pipeSpawnIntervalMs: 1600,
          obstacleSpawnIntervalMs: 3000,
          pipeGap: 250,
          maxObstacles: 1,
        );
      case Difficulty.hard:
        return DifficultySettings(
          pipeSpeed: 6,
          obstacleSpeed: 6,
          pipeSpawnIntervalMs: 1200,
          obstacleSpawnIntervalMs: 2000,
          pipeGap: 200,
          maxObstacles: 2,
        );
    }
  }
}

const String defaultCharacterId = 'neon_pilot';

const List<GameCharacter> characterCatalog = [
  GameCharacter(
    id: defaultCharacterId,
    name: 'NEON PILOT',
    cost: 0,
    primary: Color(0xFFFF00FF),
    secondary: Color(0xFFAA00AA),
    accent: Color(0xFFFFFF00),
    style: 0,
    jumpPower: 1.1,
    handling: 1.1,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'cyber_egg',
    name: 'CYBER EGG',
    cost: 100,
    primary: Color(0xFF00FF66),
    secondary: Color(0xFF007A38),
    accent: Color(0xFFCCFF00),
    style: 1,
    jumpPower: 1.05,
    handling: 1.05,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'quantum_x',
    name: 'QUANTUM X',
    cost: 200,
    primary: Color(0xFFFF0066),
    secondary: Color(0xFF660033),
    accent: Color(0xFFFFFFFF),
    style: 2,
    jumpPower: 1.0,
    handling: 1.0,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'solar_dash',
    name: 'SOLAR DASH',
    cost: 300,
    primary: Color(0xFFFFCC00),
    secondary: Color(0xFFFF6600),
    accent: Color(0xFF00FFFF),
    style: 3,
    jumpPower: 0.98,
    handling: 0.98,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'aqua_byte',
    name: 'AQUA BYTE',
    cost: 450,
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF0066FF),
    accent: Color(0xFFFFFFFF),
    style: 4,
    jumpPower: 0.95,
    handling: 0.95,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'lime_ghost',
    name: 'LIME GHOST',
    cost: 600,
    primary: Color(0xFFB6FF00),
    secondary: Color(0xFF2D6A00),
    accent: Color(0xFFFF00FF),
    style: 5,
    jumpPower: 0.92,
    handling: 0.92,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'ruby_rocket',
    name: 'RUBY ROCKET',
    cost: 800,
    primary: Color(0xFFFF2E2E),
    secondary: Color(0xFF7A0019),
    accent: Color(0xFFFFF2B2),
    style: 6,
    jumpPower: 0.9,
    handling: 0.9,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'violet_vibe',
    name: 'VIOLET VIBE',
    cost: 1050,
    primary: Color(0xFF9B5CFF),
    secondary: Color(0xFF371270),
    accent: Color(0xFF00FFB3),
    style: 7,
    jumpPower: 0.88,
    handling: 0.88,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'chrome_wave',
    name: 'CHROME WAVE',
    cost: 1350,
    primary: Color(0xFFE5E5E5),
    secondary: Color(0xFF737373),
    accent: Color(0xFFFF00A8),
    style: 8,
    jumpPower: 0.85,
    handling: 0.85,
    gravity: 0.3,
  ),
  GameCharacter(
    id: 'gold_legend',
    name: 'GOLD LEGEND',
    cost: 1700,
    primary: Color(0xFFFFD700),
    secondary: Color(0xFF8A5A00),
    accent: Color(0xFFFFFFFF),
    style: 9,
    jumpPower: 0.82,
    handling: 0.82,
    gravity: 0.3,
  ),
];

class GameCharacter {
  final String id;
  final String name;
  final int cost;
  final Color primary;
  final Color secondary;
  final Color accent;
  final int style;
  final double jumpPower;
  final double handling;
  final double gravity;

  const GameCharacter({
    required this.id,
    required this.name,
    required this.cost,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.style,
    this.jumpPower = 1.0,
    this.handling = 1.0,
    this.gravity = 0.3,
  });
}

class FloppyBirdApp extends StatelessWidget {
  const FloppyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEON FLAP 2050',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  double totalCoins = 9999;
  Set<String> unlockedCharacterIds = {defaultCharacterId};
  String selectedCharacterId = defaultCharacterId;
  int animationFrame = 0;
  Timer? animationTimer;

  GameCharacter get selectedCharacter => characterCatalog.firstWhere(
    (character) => character.id == selectedCharacterId,
    orElse: () => characterCatalog.first,
  );

  @override
  void initState() {
    super.initState();
    loadEconomy();
    startAnimation();
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    super.dispose();
  }

  void startAnimation() {
    animationTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (mounted) {
        setState(() {
          animationFrame++;
        });
      }
    });
  }

Future<void> loadEconomy() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnlocked =
        prefs.getStringList('unlocked_characters') ?? [defaultCharacterId];
    final savedSelected =
        prefs.getString('selected_character') ?? defaultCharacterId;

if (!mounted) {
      return;
    }

    setState(() {
      totalCoins = 9999;
      unlockedCharacterIds = {...savedUnlocked, defaultCharacterId};
      selectedCharacterId =
          unlockedCharacterIds.contains(savedSelected)
              ? savedSelected
              : defaultCharacterId;
    });
  }

  void navigateToGame() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
    if (result != null && result is Map) {
      setState(() {
        totalCoins = result['totalCoins'] as double;
        unlockedCharacterIds = Set<String>.from(result['unlockedCharacterIds'] as List<String>);
        selectedCharacterId = result['selectedCharacterId'] as String;
      });
    }
  }

  void openCharacterShop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CharacterShopScreen(
              totalCoins: totalCoins,
              unlockedCharacterIds: unlockedCharacterIds,
              selectedCharacterId: selectedCharacterId,
              onCharacterSelected: (character) {
                setState(() {
                  selectedCharacterId = character.id;
                });
                saveEconomy();
              },
              onCharacterPurchased: (character) {
                setState(() {
                  totalCoins -= character.cost;
                  unlockedCharacterIds.add(character.id);
                  selectedCharacterId = character.id;
                });
                saveEconomy();
              },
            ),
      ),
    );
  }

  Future<void> saveEconomy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_coins', totalCoins);
    await prefs.setStringList(
      'unlocked_characters',
      unlockedCharacterIds.toList(),
    );
    await prefs.setString('selected_character', selectedCharacterId);
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
                if (pos.dx > 80 && pos.dx < 320) {
                  if (pos.dy > 200 && pos.dy < 260) {
                    navigateToGame();
                  } else if (pos.dy > 270 && pos.dy < 330) {
                    openCharacterShop();
                  } else if (pos.dy > 340 && pos.dy < 400) {
                    SystemNavigator.pop();
                  }
                }
              },
              child: CustomPaint(
                size: const Size(400, 600),
                painter: MenuPainter(
                  animationFrame: animationFrame,
                  totalCoins: totalCoins,
                  selectedCharacter: selectedCharacter,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuPainter extends CustomPainter {
  final int animationFrame;
  final double totalCoins;
  final GameCharacter selectedCharacter;

  MenuPainter({
    required this.animationFrame,
    required this.totalCoins,
    required this.selectedCharacter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawTitle(canvas, size);
    _drawCoinHud(canvas, size);
    _drawMenuButtons(canvas, size);
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

  void _drawCharacterAvatar(
    Canvas canvas,
    Offset center,
    double scale,
    GameCharacter character,
    int animationFrame,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    final bodyPaint = Paint()..color = character.primary;
    final secondaryPaint = Paint()..color = character.secondary;
    final accentPaint =
        Paint()
          ..color = character.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final flap = sin(animationFrame * 0.25) * 2;

    switch (character.style) {
      case 0:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawCircle(const Offset(0, 0), 7, secondaryPaint);
        break;
      case 1:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 28, height: 34),
          bodyPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset.zero, width: 30, height: 36),
          -pi / 2,
          pi,
          false,
          accentPaint,
        );
        break;
      case 2:
        final path =
            Path()
              ..moveTo(0, -18)
              ..lineTo(18, 0)
              ..lineTo(0, 18)
              ..lineTo(-18, 0)
              ..close();
        canvas.drawPath(path, bodyPaint);
        canvas.drawLine(
          const Offset(-10, -10),
          const Offset(10, 10),
          accentPaint,
        );
        canvas.drawLine(
          const Offset(10, -10),
          const Offset(-10, 10),
          accentPaint,
        );
        break;
      case 3:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawCircle(const Offset(0, 0), 7, secondaryPaint);
        canvas.drawCircle(Offset.zero, 17, accentPaint);
        break;
      case 4:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 32, height: 26),
            const Radius.circular(8),
          ),
          bodyPaint,
        );
        canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), accentPaint);
        break;
      case 5:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 32, height: 28),
          bodyPaint,
        );
        canvas.drawCircle(const Offset(-7, -3), 4, secondaryPaint);
        canvas.drawCircle(const Offset(7, -3), 4, secondaryPaint);
        break;
      case 6:
        final rocket =
            Path()
              ..moveTo(18, 0)
              ..quadraticBezierTo(4, -17, -15, -10)
              ..lineTo(-8, 0)
              ..lineTo(-15, 10)
              ..quadraticBezierTo(4, 17, 18, 0)
              ..close();
        canvas.drawPath(rocket, bodyPaint);
        canvas.drawCircle(const Offset(3, 0), 5, secondaryPaint);
        break;
      case 7:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        for (int i = 0; i < 3; i++) {
          final angle = animationFrame * 0.05 + i * 2 * pi / 3;
          canvas.drawCircle(
            Offset(cos(angle) * 19, sin(angle) * 19),
            3,
            secondaryPaint,
          );
        }
        break;
      case 8:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawRect(
          Rect.fromCenter(center: const Offset(0, 0), width: 26, height: 6),
          secondaryPaint,
        );
        canvas.drawCircle(Offset.zero, 16, accentPaint);
        break;
      case 9:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        final crown =
            Path()
              ..moveTo(-12, -8)
              ..lineTo(-6, -18)
              ..lineTo(0, -9)
              ..lineTo(6, -18)
              ..lineTo(12, -8)
              ..close();
        canvas.drawPath(crown, secondaryPaint);
        break;
      default:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        break;
    }

    final wingPath =
        Path()
          ..moveTo(-6, 6 + flap)
          ..quadraticBezierTo(-2, -6 + flap, -12, flap)
          ..quadraticBezierTo(-18, 8 + flap, -6, 14 + flap)
          ..close();
    canvas.drawPath(wingPath, secondaryPaint);
    canvas.restore();
  }

  void _drawTitle(Canvas canvas, Size size) {
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
      Offset(size.width / 2 - titlePainter.width / 2, 64),
    );
  }

  void _drawCoinHud(Canvas canvas, Size size) {
    _drawCoinIcon(canvas, const Offset(24, 36), 10);

    final coinPainter = TextPainter(
      text: TextSpan(
        text: '$totalCoins',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF8800), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    coinPainter.layout();
    coinPainter.paint(canvas, const Offset(40, 24));
  }

  void _drawCoinIcon(Canvas canvas, Offset center, double radius) {
    final coinPaint = Paint()..color = const Color(0xFFFFD700);
    final coinBorder =
        Paint()
          ..color = const Color(0xFFFFF2A8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final coinGlow =
        Paint()
          ..color = const Color(0xFFFFAA00).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, radius + 3, coinGlow);
    canvas.drawCircle(center, radius, coinPaint);
    canvas.drawCircle(center, radius, coinBorder);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 4),
      Offset(center.dx, center.dy + radius - 4),
      coinBorder,
    );
  }

  void _drawMenuButtons(Canvas canvas, Size size) {
    _drawMenuButton(canvas, size, 'PLAY', 220, Color(0xFF00FF00), false);
    _drawMenuButton(canvas, size, 'CHARACTERS', 290, Color(0xFFFFD700), false);
    _drawMenuButton(canvas, size, 'EXIT', 360, Color(0xFFFF0066), false);
  }

  void _drawMenuButton(
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

  @override
  bool shouldRepaint(covariant MenuPainter oldDelegate) {
    return animationFrame != oldDelegate.animationFrame ||
        totalCoins != oldDelegate.totalCoins ||
        selectedCharacter != oldDelegate.selectedCharacter;
  }
}

class CharacterShopScreen extends StatefulWidget {
  final double totalCoins;
  final Set<String> unlockedCharacterIds;
  final String selectedCharacterId;
  final Function(GameCharacter) onCharacterSelected;
  final Function(GameCharacter) onCharacterPurchased;

  const CharacterShopScreen({
    super.key,
    required this.totalCoins,
    required this.unlockedCharacterIds,
    required this.selectedCharacterId,
    required this.onCharacterSelected,
    required this.onCharacterPurchased,
  });

  @override
  State<CharacterShopScreen> createState() => _CharacterShopScreenState();
}

class _CharacterShopScreenState extends State<CharacterShopScreen> {
  late double totalCoins;
  late Set<String> unlockedCharacterIds;
  late String selectedCharacterId;
  int animationFrame = 0;
  Timer? animationTimer;

  GameCharacter get selectedCharacter => characterCatalog.firstWhere(
    (character) => character.id == selectedCharacterId,
    orElse: () => characterCatalog.first,
  );

  @override
  void initState() {
    super.initState();
    totalCoins = widget.totalCoins;
    unlockedCharacterIds = widget.unlockedCharacterIds;
    selectedCharacterId = widget.selectedCharacterId;
    startAnimation();
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    super.dispose();
  }

  void startAnimation() {
    animationTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (mounted) {
        setState(() {
          animationFrame++;
        });
      }
    });
  }

  void handleTap(Offset pos) {
    const gridTop = 118.0;
    const rowHeight = 76.0;
    const cardHeight = 62.0;
    const leftX = 20.0;
    const rightX = 215.0;
    const cardWidth = 165.0;

    final row = ((pos.dy - gridTop) / rowHeight).floor();
    if (row < 0 || row >= 5) {
      if (pos.dy > 540 && pos.dy < 590 && pos.dx > 80 && pos.dx < 320) {
        Navigator.pop(context);
      }
      return;
    }

    final rowTop = gridTop + row * rowHeight;
    if (pos.dy < rowTop || pos.dy > rowTop + cardHeight) {
      return;
    }

    int? column;
    if (pos.dx >= leftX && pos.dx <= leftX + cardWidth) {
      column = 0;
    } else if (pos.dx >= rightX && pos.dx <= rightX + cardWidth) {
      column = 1;
    }

    if (column == null) {
      return;
    }

    final index = row * 2 + column;
    if (index >= characterCatalog.length) {
      return;
    }

    final character = characterCatalog[index];
    if (unlockedCharacterIds.contains(character.id)) {
      setState(() {
        selectedCharacterId = character.id;
      });
      widget.onCharacterSelected(character);
    } else if (totalCoins >= character.cost) {
      setState(() {
        totalCoins -= character.cost;
        unlockedCharacterIds.add(character.id);
        selectedCharacterId = character.id;
      });
      widget.onCharacterPurchased(character);
    }
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
                handleTap(pos);
              },
              child: CustomPaint(
                size: const Size(400, 600),
                painter: CharacterShopPainter(
                  animationFrame: animationFrame,
                  totalCoins: totalCoins,
                  selectedCharacter: selectedCharacter,
                  unlockedCharacterIds: unlockedCharacterIds,
                  characterCatalog: characterCatalog,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CharacterShopPainter extends CustomPainter {
  final int animationFrame;
  final double totalCoins;
  final GameCharacter selectedCharacter;
  final Set<String> unlockedCharacterIds;
  final List<GameCharacter> characterCatalog;

  CharacterShopPainter({
    required this.animationFrame,
    required this.totalCoins,
    required this.selectedCharacter,
    required this.unlockedCharacterIds,
    required this.characterCatalog,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawTitle(canvas, size);
    _drawCoinHud(canvas, size);
    _drawCharacterCards(canvas, size);
    _drawBackButton(canvas, size);
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

  void _drawTitle(Canvas canvas, Size size) {
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'CHARACTERS',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 16)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(size.width / 2 - titlePainter.width / 2, 36),
    );
  }

  void _drawCoinHud(Canvas canvas, Size size) {
    _drawCoinIcon(canvas, Offset(size.width / 2 - 44, 88), 10);
    final coinsPainter = TextPainter(
      text: TextSpan(
        text: '$totalCoins COINS',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    coinsPainter.layout();
    coinsPainter.paint(
      canvas,
      Offset(size.width / 2 - coinsPainter.width / 2 + 12, 78),
    );
  }

  void _drawCoinIcon(Canvas canvas, Offset center, double radius) {
    final coinPaint = Paint()..color = const Color(0xFFFFD700);
    final coinBorder =
        Paint()
          ..color = const Color(0xFFFFF2A8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final coinGlow =
        Paint()
          ..color = const Color(0xFFFFAA00).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, radius + 3, coinGlow);
    canvas.drawCircle(center, radius, coinPaint);
    canvas.drawCircle(center, radius, coinBorder);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 4),
      Offset(center.dx, center.dy + radius - 4),
      coinBorder,
    );
  }

  void _drawCharacterCards(Canvas canvas, Size size) {
    for (int i = 0; i < characterCatalog.length; i++) {
      final row = i ~/ 2;
      final col = i % 2;
      final x = col == 0 ? 20.0 : 215.0;
      final y = 118.0 + row * 76;
      _drawCharacterCard(
        canvas,
        characterCatalog[i],
        Rect.fromLTWH(x, y, 165, 62),
      );
    }
  }

  void _drawCharacterCard(Canvas canvas, GameCharacter character, Rect rect) {
    final isUnlocked = unlockedCharacterIds.contains(character.id);
    final isSelected = selectedCharacter.id == character.id;
    final canAfford = totalCoins >= character.cost;
    final cardColor =
        isUnlocked
            ? character.primary.withValues(alpha: 0.22)
            : const Color(0xFF1A1A2A).withValues(alpha: 0.92);
    final borderColor =
        isSelected
            ? const Color(0xFFFFFFFF)
            : isUnlocked
            ? character.primary
            : canAfford
            ? const Color(0xFFFFD700)
            : const Color(0xFF555555);
    final cardRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    canvas.drawRRect(cardRect, Paint()..color = cardColor);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2,
    );

    _drawCharacterAvatar(
      canvas,
      Offset(rect.left + 28, rect.center.dy),
      0.72,
      character,
      animationFrame,
    );

    final namePainter = TextPainter(
      text: TextSpan(
        text: character.name,
        style: TextStyle(
          color: isUnlocked ? Colors.white : const Color(0xFFB8B8C8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    namePainter.layout(maxWidth: 104);
    namePainter.paint(canvas, Offset(rect.left + 54, rect.top + 10));

    final statusText =
        isSelected
            ? 'SELECTED'
            : isUnlocked
            ? 'UNLOCKED'
            : '${character.cost} COINS';
    final statusPainter = TextPainter(
      text: TextSpan(
        text: statusText,
        style: TextStyle(
          color:
              isSelected
                  ? const Color(0xFF00FFFF)
                  : isUnlocked
                  ? const Color(0xFF7CFF7C)
                  : canAfford
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF6666),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    statusPainter.layout(maxWidth: 104);
    statusPainter.paint(canvas, Offset(rect.left + 54, rect.top + 34));
  }

  void _drawCharacterAvatar(
    Canvas canvas,
    Offset center,
    double scale,
    GameCharacter character,
    int animationFrame,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    final bodyPaint = Paint()..color = character.primary;
    final secondaryPaint = Paint()..color = character.secondary;
    final accentPaint =
        Paint()
          ..color = character.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final flap = sin(animationFrame * 0.25) * 2;

    switch (character.style) {
      case 0:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawCircle(const Offset(0, 0), 7, secondaryPaint);
        break;
      case 1:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 28, height: 34),
          bodyPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset.zero, width: 30, height: 36),
          -pi / 2,
          pi,
          false,
          accentPaint,
        );
        break;
      case 2:
        final path =
            Path()
              ..moveTo(0, -18)
              ..lineTo(18, 0)
              ..lineTo(0, 18)
              ..lineTo(-18, 0)
              ..close();
        canvas.drawPath(path, bodyPaint);
        canvas.drawLine(
          const Offset(-10, -10),
          const Offset(10, 10),
          accentPaint,
        );
        canvas.drawLine(
          const Offset(10, -10),
          const Offset(-10, 10),
          accentPaint,
        );
        break;
      case 3:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawCircle(const Offset(0, 0), 7, secondaryPaint);
        canvas.drawCircle(Offset.zero, 17, accentPaint);
        break;
      case 4:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 32, height: 26),
            const Radius.circular(8),
          ),
          bodyPaint,
        );
        canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), accentPaint);
        break;
      case 5:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 32, height: 28),
          bodyPaint,
        );
        canvas.drawCircle(const Offset(-7, -3), 4, secondaryPaint);
        canvas.drawCircle(const Offset(7, -3), 4, secondaryPaint);
        break;
      case 6:
        final rocket =
            Path()
              ..moveTo(18, 0)
              ..quadraticBezierTo(4, -17, -15, -10)
              ..lineTo(-8, 0)
              ..lineTo(-15, 10)
              ..quadraticBezierTo(4, 17, 18, 0)
              ..close();
        canvas.drawPath(rocket, bodyPaint);
        canvas.drawCircle(const Offset(3, 0), 5, secondaryPaint);
        break;
      case 7:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        for (int i = 0; i < 3; i++) {
          final angle = animationFrame * 0.05 + i * 2 * pi / 3;
          canvas.drawCircle(
            Offset(cos(angle) * 19, sin(angle) * 19),
            3,
            secondaryPaint,
          );
        }
        break;
      case 8:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawRect(
          Rect.fromCenter(center: const Offset(0, 0), width: 26, height: 6),
          secondaryPaint,
        );
        canvas.drawCircle(Offset.zero, 16, accentPaint);
        break;
      case 9:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        final crown =
            Path()
              ..moveTo(-12, -8)
              ..lineTo(-6, -18)
              ..lineTo(0, -9)
              ..lineTo(6, -18)
              ..lineTo(12, -8)
              ..close();
        canvas.drawPath(crown, secondaryPaint);
        break;
      default:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        break;
    }

    final wingPath =
        Path()
          ..moveTo(-6, 6 + flap)
          ..quadraticBezierTo(-2, -6 + flap, -12, flap)
          ..quadraticBezierTo(-18, 8 + flap, -6, 14 + flap)
          ..close();
    canvas.drawPath(wingPath, secondaryPaint);
    canvas.restore();
  }

  void _drawBackButton(Canvas canvas, Size size) {
    _drawMenuButton(canvas, size, 'BACK', 555, const Color(0xFF00AAFF), false);
  }

  void _drawMenuButton(
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

  @override
  bool shouldRepaint(covariant CharacterShopPainter oldDelegate) {
    return animationFrame != oldDelegate.animationFrame ||
        totalCoins != oldDelegate.totalCoins ||
        selectedCharacter != oldDelegate.selectedCharacter ||
        unlockedCharacterIds != oldDelegate.unlockedCharacterIds;
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
  double totalCoins = 9999;
  double runCoins = 0;
  Set<String> unlockedCharacterIds = {defaultCharacterId};
  String selectedCharacterId = defaultCharacterId;
  bool isGameOver = false;
  bool hasStarted = false;
  bool showDifficultySelector = true;
  bool showCharacterShop = false;
  Difficulty selectedDifficulty = Difficulty.normal;
  Timer? pipeTimer;
  Timer? obstacleTimer;
  Timer? gameLoop;
  int frameCount = 0;

  GameCharacter get selectedCharacter => characterCatalog.firstWhere(
    (character) => character.id == selectedCharacterId,
    orElse: () => characterCatalog.first,
  );

  @override
  void initState() {
    super.initState();
    birdY = 250;
    loadEconomy();
    // Game loop will be started when game begins
  }

  Future<void> loadEconomy() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnlocked =
        prefs.getStringList('unlocked_characters') ?? [defaultCharacterId];
    final savedSelected =
        prefs.getString('selected_character') ?? defaultCharacterId;

if (!mounted) {
      return;
    }

    setState(() {
      totalCoins = 9999;
      unlockedCharacterIds = {...savedUnlocked, defaultCharacterId};
      selectedCharacterId =
          unlockedCharacterIds.contains(savedSelected)
              ? savedSelected
              : defaultCharacterId;
    });
  }

  Future<void> saveEconomy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_coins', totalCoins);
    await prefs.setStringList(
      'unlocked_characters',
      unlockedCharacterIds.toList(),
    );
    await prefs.setString('selected_character', selectedCharacterId);
  }

  void startGameLoop() {
    // Game loop is started in startGame() and selectDifficulty()
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    pipeTimer?.cancel();
    obstacleTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    hasStarted = true;
    showDifficultySelector = false;
    isGameOver = false;
    birdY = 250;
    birdVelocity = 0;
    birdRotation = 0;
    score = 0;
    runCoins = 0;
    particles.clear();

    pipeTimer?.cancel();
    obstacleTimer?.cancel();
    gameLoop?.cancel();
    pipes.clear();
    obstacles.clear();

    final settings = DifficultySettings.forDifficulty(selectedDifficulty);

    // Start game loop at 30 FPS
    gameLoop = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (!mounted) {
        return;
      }

      update();
      frameCount++;

      if (hasStarted) {
        setState(() {});
      }
    });

    pipeTimer = Timer.periodic(
      Duration(milliseconds: settings.pipeSpawnIntervalMs),
      (_) {
        if (!isGameOver && mounted) {
          pipes.add(Pipe.generate(selectedDifficulty));
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
            selectedDifficulty,
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
      birdVelocity = jumpVelocity * selectedCharacter.jumpPower;
    }
  }

  void goBackToMenu() async {
    if (!mounted) return;
    await saveEconomy();
    if (!mounted) return;
    Navigator.pop(context, {'totalCoins': totalCoins, 'unlockedCharacterIds': unlockedCharacterIds, 'selectedCharacterId': selectedCharacterId});
  }

  void resetGame() {
    hasStarted = false;
    showDifficultySelector = true;
    isGameOver = false;
    birdY = 250;
    birdVelocity = 0;
    birdRotation = 0;
    score = 0;
    runCoins = 0;
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

  void openCharacterShop() {
    showCharacterShop = true;
    setState(() {});
  }

  void closeCharacterShop() {
    showCharacterShop = false;
    setState(() {});
  }

  void buyOrSelectCharacter(GameCharacter character) {
    if (unlockedCharacterIds.contains(character.id)) {
      selectedCharacterId = character.id;
      unawaited(saveEconomy());
      setState(() {});
      return;
    }

    if (totalCoins < character.cost) {
      return;
    }

    totalCoins -= character.cost;
    unlockedCharacterIds.add(character.id);
    selectedCharacterId = character.id;
    unawaited(saveEconomy());
    setState(() {});
  }

  void handleCharacterShopTap(Offset pos) {
    if (pos.dx > 90 && pos.dx < 310 && pos.dy > 532 && pos.dy < 578) {
      closeCharacterShop();
      return;
    }

    const gridTop = 118.0;
    const rowHeight = 76.0;
    const cardHeight = 62.0;
    const leftX = 20.0;
    const rightX = 215.0;
    const cardWidth = 165.0;

    final row = ((pos.dy - gridTop) / rowHeight).floor();
    if (row < 0 || row >= 5) {
      return;
    }

    final rowTop = gridTop + row * rowHeight;
    if (pos.dy < rowTop || pos.dy > rowTop + cardHeight) {
      return;
    }

    int? column;
    if (pos.dx >= leftX && pos.dx <= leftX + cardWidth) {
      column = 0;
    } else if (pos.dx >= rightX && pos.dx <= rightX + cardWidth) {
      column = 1;
    }

    if (column == null) {
      return;
    }

    final index = row * 2 + column;
    if (index >= characterCatalog.length) {
      return;
    }

    buyOrSelectCharacter(characterCatalog[index]);
  }

  void selectDifficulty(Difficulty diff) {
    // Immediately update UI state
    if (!mounted) return;
    
    setState(() {
      selectedDifficulty = diff;
      showDifficultySelector = false;
      showCharacterShop = false;
    });

    // Defer all heavy work to prevent timeout
    Future.microtask(() {
      if (!mounted) return;
      
      // Cancel existing timers
      pipeTimer?.cancel();
      obstacleTimer?.cancel();
      gameLoop?.cancel();

      // Reset game state
      isGameOver = false;
      birdY = 250;
      birdVelocity = 0;
      birdRotation = 0;
      score = 0;
      runCoins = 0;
      pipes.clear();
      obstacles.clear();
      particles.clear();
      hasStarted = true;

      final settings = DifficultySettings.forDifficulty(selectedDifficulty);

// Start game loop
       gameLoop = Timer.periodic(const Duration(milliseconds: 32), (timer) {
         if (!mounted) {
           return;
         }
         
         update();
         frameCount++;
         
         if (hasStarted) {
           setState(() {});
         }
       });

      pipeTimer = Timer.periodic(
        Duration(milliseconds: settings.pipeSpawnIntervalMs),
        (_) {
          if (!isGameOver && mounted) {
            pipes.add(Pipe.generate(selectedDifficulty));
          }
        },
      );

      obstacleTimer = Timer.periodic(
        Duration(milliseconds: settings.obstacleSpawnIntervalMs),
        (_) {
          if (!isGameOver && obstacles.length < settings.maxObstacles && mounted) {
            obstacles.add(ExtraObstacle.generate());
          }
        },
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!isGameOver && mounted) {
          pipes.add(
            Pipe.generate(
              selectedDifficulty,
            ),
          );
        }
      });
    });
  }

  void addParticles(double x, double y) {
    for (int i = 0; i < 10; i++) {
      particles.add(Particle(x: x, y: y, frameCount: 0));
    }
  }

  void update() {
    final settings = DifficultySettings.forDifficulty(selectedDifficulty);
    final characterGravity = gravity / selectedCharacter.handling;

    double speedBoost = 0;
    if (selectedDifficulty == Difficulty.easy) {
      speedBoost = (score / 30).clamp(0, 10);
    } else if (selectedDifficulty == Difficulty.normal) {
      speedBoost = (score / 25).clamp(0, 13);
    } else if (selectedDifficulty == Difficulty.hard) {
      speedBoost = (score / 20).clamp(0, 16);
    }

    birdVelocity += characterGravity;
    birdY += birdVelocity;

    birdRotation = birdVelocity * 0.05;
    if (birdRotation > 0.8) birdRotation = 0.8;
    if (birdRotation < -0.8) birdRotation = -0.8;

    for (var pipe in pipes) {
      pipe.x -= settings.pipeSpeed + speedBoost;
    }

    pipes.removeWhere((pipe) => pipe.x < -pipeWidth);

    for (var obs in obstacles) {
      obs.x -= settings.obstacleSpeed + speedBoost;
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
totalCoins += 0.25;
                         runCoins += 0.25;
        unawaited(saveEconomy());
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
        if (birdY + birdSize / 2 > pipe.topHeight + pipe.gap) {
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
    gameLoop?.cancel();
    pipeTimer?.cancel();
    obstacleTimer?.cancel();
    unawaited(saveEconomy());
    if (birdY + birdSize / 2 < 600 - groundHeight) {
      birdVelocity = gravity * 3;
    }
    addParticles(birdStartX, birdY);
    setState(() {});
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
                if (showCharacterShop) {
                  handleCharacterShopTap(pos);
                  return;
                }
                if (showDifficultySelector) {
                  if (pos.dx > 80 && pos.dx < 320) {
                    if (pos.dy > 200 && pos.dy < 260) {
                      selectDifficulty(Difficulty.easy);
                    } else if (pos.dy > 270 && pos.dy < 330) {
                      selectDifficulty(Difficulty.normal);
                    } else if (pos.dy > 340 && pos.dy < 400) {
                      selectDifficulty(Difficulty.hard);
                    } else if (pos.dy > 440 && pos.dy < 500) {
                      goBackToMenu();
                    }
                  }
                } else if (isGameOver) {
                  // Game over buttons
                  if (pos.dx > 100 && pos.dx < 300) {
                    if (pos.dy > 292 && pos.dy < 337) {
                      // RESTART button
                      resetGame();
                      startGame();
                    } else if (pos.dy > 352 && pos.dy < 397) {
                      // MAIN MENU button
                      goBackToMenu();
                    } else if (pos.dy > 412 && pos.dy < 457) {
                      // QUIT button
                      exitGame();
                    }
                  }
                }
              },
              onTap: () {
                if (!isGameOver && !showDifficultySelector && !showCharacterShop) {
                  if (hasStarted) {
                    jump();
                  }
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
                  selectedDifficulty: selectedDifficulty,
                  showDifficultySelector: showDifficultySelector,
                  showCharacterShop: showCharacterShop,
                  totalCoins: totalCoins,
                  runCoins: runCoins,
                  selectedCharacter: selectedCharacter,
                  unlockedCharacterIds: unlockedCharacterIds,
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
  final double gap;

  Pipe({required this.x, required this.topHeight, required this.gap, this.scored = false});

  static Pipe generate(Difficulty difficulty) {
    final random = Random();
    double minGap, maxGap;
    switch (difficulty) {
      case Difficulty.easy:
        minGap = 200;
        maxGap = 300;
        break;
      case Difficulty.normal:
        minGap = 240;
        maxGap = 280;
        break;
      case Difficulty.hard:
        minGap = 240;
        maxGap = 270;
        break;
    }
    final actualGap = minGap + random.nextDouble() * (maxGap - minGap);
    final minTopHeight = 80;
    final maxTopHeight = 420 - actualGap;
    final topHeight =
        minTopHeight + random.nextDouble() * (maxTopHeight - minTopHeight);
    return Pipe(x: 400, topHeight: topHeight, gap: actualGap);
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
      color = Color.fromARGB(
        0xFF,
        0x00 + Random().nextInt(0xFF),
        0xFF,
        0xFF - Random().nextInt(0x80),
      );

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
  final Difficulty selectedDifficulty;
  final bool showDifficultySelector;
  final bool showCharacterShop;
  final double totalCoins;
  final double runCoins;
  final GameCharacter selectedCharacter;
  final Set<String> unlockedCharacterIds;

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
    required this.selectedDifficulty,
    required this.showDifficultySelector,
    required this.showCharacterShop,
    required this.totalCoins,
    required this.runCoins,
    required this.selectedCharacter,
    required this.unlockedCharacterIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawParticles(canvas, size);
    _drawPipes(canvas, size);
    _drawObstacles(canvas, size);
    
    if (!showDifficultySelector && !showCharacterShop) {
      _drawBird(canvas, size);
    }

    if (showCharacterShop) {
      _drawCharacterShop(canvas, size);
    } else if (showDifficultySelector) {
      _drawDifficultySelector(canvas, size);
    } else if (!hasStarted) {
      _drawStartMessage(canvas, size);
    }

    if (isGameOver) {
      _drawGameOver(canvas, size);
    }

    // Draw HUD (score and coins) during gameplay
    if (hasStarted && !showDifficultySelector && !showCharacterShop) {
      _drawHUD(canvas, size);
    }
  }

  void _drawHUD(Canvas canvas, Size size) {
    // Draw score
    final scorePainter = TextPainter(
      text: TextSpan(
        text: 'SCORE: $score',
        style: TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 10)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(canvas, Offset(20, 20));

    // Draw coins
    _drawCoinIcon(canvas, Offset(size.width - 80, 35), 12);
    final coinsPainter = TextPainter(
      text: TextSpan(
        text: runCoins.toStringAsFixed(1),
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF8800), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    coinsPainter.layout();
    coinsPainter.paint(canvas, Offset(size.width - 60, 24));
  }

  void _drawCoinIcon(Canvas canvas, Offset center, double radius) {
    final coinPaint = Paint()..color = Color(0xFFFFD700);
    final coinBorder =
        Paint()
          ..color = Color(0xFFFFF2A8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final coinGlow =
        Paint()
          ..color = Color(0xFFFFAA00).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, radius + 3, coinGlow);
    canvas.drawCircle(center, radius, coinPaint);
    canvas.drawCircle(center, radius, coinBorder);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 4),
      Offset(center.dx, center.dy + radius - 4),
      coinBorder,
    );
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

  void _drawParticles(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint =
          Paint()
            ..color = p.color.withValues(alpha: 1 - p.frameCount / 30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(p.x, p.y), 3 + Random().nextDouble() * 2, paint);
    }
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

    final bottomPipeStart = pipe.topHeight + pipe.gap;
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

  void _drawCharacterAvatar(
    Canvas canvas,
    Offset center,
    double scale,
    GameCharacter character,
    int animationFrame,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    final bodyPaint = Paint()..color = character.primary;
    final secondaryPaint = Paint()..color = character.secondary;
    final accentPaint =
        Paint()
          ..color = character.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final flap = sin(animationFrame * 0.25) * 2;

    switch (character.style) {
      case 0:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawCircle(const Offset(0, 0), 7, secondaryPaint);
        break;
      case 1:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 28, height: 34),
          bodyPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset.zero, width: 30, height: 36),
          -pi / 2,
          pi,
          false,
          accentPaint,
        );
        break;
      case 2:
        final path =
            Path()
              ..moveTo(0, -18)
              ..lineTo(18, 0)
              ..lineTo(0, 18)
              ..lineTo(-18, 0)
              ..close();
        canvas.drawPath(path, bodyPaint);
        canvas.drawLine(
          const Offset(-10, -10),
          const Offset(10, 10),
          accentPaint,
        );
        canvas.drawLine(
          const Offset(10, -10),
          const Offset(-10, 10),
          accentPaint,
        );
        break;
      case 3:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawCircle(const Offset(0, 0), 7, secondaryPaint);
        canvas.drawCircle(Offset.zero, 17, accentPaint);
        break;
      case 4:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 32, height: 26),
            const Radius.circular(8),
          ),
          bodyPaint,
        );
        canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), accentPaint);
        break;
      case 5:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 32, height: 28),
          bodyPaint,
        );
        canvas.drawCircle(const Offset(-7, -3), 4, secondaryPaint);
        canvas.drawCircle(const Offset(7, -3), 4, secondaryPaint);
        break;
      case 6:
        final rocket =
            Path()
              ..moveTo(18, 0)
              ..quadraticBezierTo(4, -17, -15, -10)
              ..lineTo(-8, 0)
              ..lineTo(-15, 10)
              ..quadraticBezierTo(4, 17, 18, 0)
              ..close();
        canvas.drawPath(rocket, bodyPaint);
        canvas.drawCircle(const Offset(3, 0), 5, secondaryPaint);
        break;
      case 7:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        for (int i = 0; i < 3; i++) {
          final angle = animationFrame * 0.05 + i * 2 * pi / 3;
          canvas.drawCircle(
            Offset(cos(angle) * 19, sin(angle) * 19),
            3,
            secondaryPaint,
          );
        }
        break;
      case 8:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        canvas.drawRect(
          Rect.fromCenter(center: const Offset(0, 0), width: 26, height: 6),
          secondaryPaint,
        );
        canvas.drawCircle(Offset.zero, 16, accentPaint);
        break;
      case 9:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        final crown =
            Path()
              ..moveTo(-12, -8)
              ..lineTo(-6, -18)
              ..lineTo(0, -9)
              ..lineTo(6, -18)
              ..lineTo(12, -8)
              ..close();
        canvas.drawPath(crown, secondaryPaint);
        break;
      default:
        canvas.drawCircle(Offset.zero, 15, bodyPaint);
        break;
    }

    final wingPath =
        Path()
          ..moveTo(-6, 6 + flap)
          ..quadraticBezierTo(-2, -6 + flap, -12, flap)
          ..quadraticBezierTo(-18, 8 + flap, -6, 14 + flap)
          ..close();
    canvas.drawPath(wingPath, secondaryPaint);
    canvas.restore();
  }

  void _drawBird(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(100, birdY);
    canvas.rotate(birdRotation);

    final glowPaint =
        Paint()
          ..color = selectedCharacter.primary.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, 18, glowPaint);

    _drawCharacterAvatar(
      canvas,
      Offset.zero,
      1,
      selectedCharacter,
      isGameOver ? 0 : frameCount,
    );

    final energyPaint =
        Paint()
          ..color = selectedCharacter.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, 15, energyPaint);

    final wingPaint = Paint()..color = selectedCharacter.secondary;
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

  void _drawDifficultySelector(Canvas canvas, Size size) {
    _drawDifficultyButton(
      canvas,
      size,
      'EASY',
      230,
      Color(0xFF00FF00),
      selectedDifficulty == Difficulty.easy,
    );
    _drawDifficultyButton(
      canvas,
      size,
      'NORMAL',
      300,
      Color(0xFF00AAFF),
      selectedDifficulty == Difficulty.normal,
    );
    _drawDifficultyButton(
      canvas,
      size,
      'HARD',
      370,
      Color(0xFFFF0066),
      selectedDifficulty == Difficulty.hard,
    );

    _drawBackButton(canvas, size);
  }

  void _drawCharacterShop(Canvas canvas, Size size) {
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'CHARACTERS',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 16)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(size.width / 2 - titlePainter.width / 2, 36),
    );

    for (int i = 0; i < characterCatalog.length; i++) {
      final row = i ~/ 2;
      final col = i % 2;
      final x = col == 0 ? 20.0 : 215.0;
      final y = 118.0 + row * 76;
      _drawCharacterCard(
        canvas,
        characterCatalog[i],
        Rect.fromLTWH(x, y, 165, 62),
      );
    }

    _drawDifficultyButton(
      canvas,
      size,
      'BACK',
      555,
      const Color(0xFF00AAFF),
      false,
    );
  }

  void _drawCharacterCard(Canvas canvas, GameCharacter character, Rect rect) {
    final isUnlocked = unlockedCharacterIds.contains(character.id);
    final isSelected = selectedCharacter.id == character.id;
    final canAfford = totalCoins >= character.cost;
    final cardColor =
        isUnlocked
            ? character.primary.withValues(alpha: 0.22)
            : const Color(0xFF1A1A2A).withValues(alpha: 0.92);
    final borderColor =
        isSelected
            ? const Color(0xFFFFFFFF)
            : isUnlocked
            ? character.primary
            : canAfford
            ? const Color(0xFFFFD700)
            : const Color(0xFF555555);
    final cardRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    canvas.drawRRect(cardRect, Paint()..color = cardColor);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2,
    );

    _drawCharacterAvatar(
      canvas,
      Offset(rect.left + 28, rect.center.dy),
      0.72,
      character,
      frameCount,
    );

    final namePainter = TextPainter(
      text: TextSpan(
        text: character.name,
        style: TextStyle(
          color: isUnlocked ? Colors.white : const Color(0xFFB8B8C8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    namePainter.layout(maxWidth: 104);
    namePainter.paint(canvas, Offset(rect.left + 54, rect.top + 10));

    final statusText =
        isSelected
            ? 'SELECTED'
            : isUnlocked
            ? 'UNLOCKED'
            : '${character.cost} COINS';
    final statusPainter = TextPainter(
      text: TextSpan(
        text: statusText,
        style: TextStyle(
          color:
              isSelected
                  ? const Color(0xFF00FFFF)
                  : isUnlocked
                  ? const Color(0xFF7CFF7C)
                  : canAfford
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF6666),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    statusPainter.layout(maxWidth: 104);
    statusPainter.paint(canvas, Offset(rect.left + 54, rect.top + 34));
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

  void _drawBackButton(Canvas canvas, Size size) {
    _drawDifficultyButton(
      canvas,
      size,
      'BACK',
      450,
      const Color(0xFFFF0066),
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
        center: Offset(size.width / 2, 320),
        width: 280,
        height: 280,
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
        text: 'SCORE: $score   +$runCoins COINS',
        style: TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: 20,
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

    // Draw three buttons
    _drawGameOverButton(canvas, size, 'RESTART', 310, Color(0xFF00FF00));
    _drawGameOverButton(canvas, size, 'MAIN MENU', 370, Color(0xFFFFD700));
    _drawGameOverButton(canvas, size, 'QUIT', 430, Color(0xFFFF0066));
  }

  void _drawGameOverButton(Canvas canvas, Size size, String text, double y, Color color) {
    final buttonPaint = Paint()..color = color.withValues(alpha: 0.4);
    final borderPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, y),
        width: 200,
        height: 45,
      ),
      const Radius.circular(22),
    );
    canvas.drawRRect(buttonRect, borderPaint);
    canvas.drawRRect(buttonRect, buttonPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
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

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
