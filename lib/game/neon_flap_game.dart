import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

import 'package:neon_flap_2100/core/constants/game_constants.dart';
import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/game/components/background.dart';
import 'package:neon_flap_2100/game/components/coin.dart';
import 'package:neon_flap_2100/game/components/glow_particle.dart';
import 'package:neon_flap_2100/game/components/obstacle.dart';
import 'package:neon_flap_2100/game/components/player.dart';
import 'package:neon_flap_2100/game/components/pipes.dart';
import 'package:neon_flap_2100/game/game_controller.dart';
import 'package:neon_flap_2100/models/character.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/services/difficulty_service.dart';
import 'package:neon_flap_2100/services/vibration_service.dart';

/// The main Flame game. Owns the world, the spawn/object-pool system, the
/// dynamic difficulty application and all collision/scoring rules. The Flutter
/// UI communicates through [controller].
class NeonFlapGame extends FlameGame {
  NeonFlapGame({
    required this.controller,
    required this.character,
    required this.difficulty,
  });

  final GameController controller;
  final Character character;
  final DifficultyService difficulty;

  late Player player;
  late CityBackground bg;
  late Ground ground;

  final List<PipePair> _pipePool = [];
  final List<Coin> _coinPool = [];
  final List<Obstacle> _obstaclePool = [];

  double get worldHeight => size.y;
  double playerX = 0;
  double groundHeight = 0;
  double _speed = 150;
  double _currentGap = GameConstants.pipeGap;
  int _colorIndex = 0;
  double _shakeTime = 0;
  final Random _rnd = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    playerX = size.x * 0.28;
    groundHeight = max(40, size.y * 0.08);

    bg = CityBackground(worldSize: size);
    ground = Ground(worldSize: size, height: groundHeight);
    add(bg);

    player = Player(character: character);
    player.position = Vector2(playerX, size.y * 0.45);
    player.frozen = true;
    add(player);

    add(ground);

    // Pre-allocate pooled objects (object pooling for 60 FPS).
    for (var i = 0; i < GameConstants.maxPipePool; i++) {
      final p = PipePair();
      p.recycle();
      _pipePool.add(p);
      add(p);
    }
    for (var i = 0; i < GameConstants.maxObjectPool; i++) {
      final c = Coin();
      c.recycle();
      _coinPool.add(c);
      add(c);
      final o = Obstacle();
      o.recycle();
      _obstaclePool.add(o);
      add(o);
    }

    controller.startCountdown();
  }

  /// Called by the UI after the countdown finishes.
  void startPlay() {
    player.frozen = false;
    controller.beginPlay();
  }

  /// Tap / input handler invoked by the UI.
  void flap() {
    if (controller.phase != GamePhase.playing || player.dead) return;
    player.flap();
    controller.addFlap();
    sl<AudioService>().playSfx(Sfx.tap);
    sl<VibrationService>().selection();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateShake(dt);
    if (controller.phase != GamePhase.playing) return;

    // Dynamic difficulty.
    final score = controller.score;
    _speed = difficulty.speedAt(score);
    _currentGap = difficulty.gapAt(score);

    bg.advance(_speed, dt);
    ground.advance(_speed, dt);

    _updatePipes(dt);
    _updateCoins(dt);
    _updateObstacles(dt);
    _maybeSpawn();
    _checkCollisions();
  }

  // ---------------------------------------------------------------------------
  // Update helpers
  // ---------------------------------------------------------------------------

  /// Manual screen shake via the camera viewfinder offset (decays over time).
  void _updateShake(double dt) {
    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final t = _shakeTime * 40;
      camera.viewfinder.position =
          Vector2(sin(t * 1.7) * 9, cos(t * 2.3) * 9);
    } else if (camera.viewfinder.position.length > 0.001) {
      camera.viewfinder.position = Vector2.zero();
    }
  }

  void _updatePipes(double dt) {
    for (final p in _pipePool) {
      if (!p.active) continue;
      p.update(dt);
      if (!p.passed && p.rightEdge < playerX) {
        p.passed = true;
        controller.addScore();
      }
      if (p.position.x + GameConstants.pipeWidth < -20) p.recycle();
    }
  }

  void _updateCoins(double dt) {
    final attractR = 24 + 70 * character.stats.coinAttraction;
    for (final c in _coinPool) {
      if (!c.active) continue;
      // Magnet: pull nearby coins toward the player.
      final dist = (c.position - player.position).length;
      if (dist < attractR) {
        final f = (dt * (1 - dist / attractR) * 6).clamp(0.0, 1.0);
        c.magnetize(player.position, f);
      } else {
        c.update(dt);
      }
      if (c.position.x < -30) c.recycle();
    }
  }

  void _updateObstacles(double dt) {
    for (final o in _obstaclePool) {
      if (!o.active) continue;
      o.update(dt);
      if (o.position.x < -60) o.recycle();
    }
  }

  // ---------------------------------------------------------------------------
  // Spawning (pooled)
  // ---------------------------------------------------------------------------

  PipePair? _acquirePipe() {
    for (final p in _pipePool) {
      if (!p.active) return p;
    }
    return null;
  }

  Coin? _acquireCoin() {
    for (final c in _coinPool) {
      if (!c.active) return c;
    }
    return null;
  }

  Obstacle? _acquireObstacle() {
    for (final o in _obstaclePool) {
      if (!o.active) return o;
    }
    return null;
  }

  void _maybeSpawn() {
    // Spawn a new pipe when the rightmost one has cleared the spacing.
    var rightmost = -double.infinity;
    for (final p in _pipePool) {
      if (p.active && p.position.x > rightmost) rightmost = p.position.x;
    }
    if (rightmost > size.x - GameConstants.pipeSpacing) return;

    final color = NeonPalette.pipeCycle[_colorIndex++ % NeonPalette.pipeCycle.length];
    final gap = _currentGap;
    final margin = 40.0;
    final minY = gap / 2 + margin;
    final maxY = worldHeight - groundHeight - gap / 2 - margin;
    final centerY = minY + _rnd.nextDouble() * (maxY - minY);
    final score = controller.score;

    final pipe = _acquirePipe();
    if (pipe != null) {
      pipe.spawn(
        x: size.x + GameConstants.pipeWidth,
        centerY: centerY,
        gap: gap,
        speed: _speed,
        worldHeight: worldHeight,
        color: color,
      );
    }

    // Coins ride through the gap for satisfying collection lines.
    final coinCount = 1 + _rnd.nextInt(3);
    for (var i = 0; i < coinCount; i++) {
      final coin = _acquireCoin();
      if (coin == null) break;
      coin.spawn(
        position: Vector2(
          size.x + GameConstants.pipeWidth + 60 + i * 40,
          centerY,
        ),
        speed: _speed,
      );
    }

    // Optional obstacle inside a wall region (fair: never in the gap).
    final freq = difficulty.config.obstacleFrequencyForScore(score);
    if (freq > 0 && _rnd.nextDouble() < freq) {
      final obs = _acquireObstacle();
      if (obs != null) {
        final isHazard = difficulty.config.hazards && _rnd.nextDouble() < 0.5;
        final inTop = _rnd.nextBool();
        final wallY = inTop
            ? (gap / 2 + margin) * 0.5
            : (maxY + (worldHeight - groundHeight)) / 2;
        final obSpeed = isHazard
            ? difficulty.config.obstacleSpeedForScore(score) * 1.8
            : difficulty.config.obstacleSpeedForScore(score);
        obs.spawn(
          x: size.x + GameConstants.pipeWidth + 20,
          baseY: wallY,
          amplitude: 40,
          horizontalSpeed: obSpeed,
          worldHeight: worldHeight,
          kind: isHazard ? ObstacleKind.hazard : ObstacleKind.drifting,
          color: isHazard ? NeonPalette.red : NeonPalette.magenta,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Collisions & scoring
  // ---------------------------------------------------------------------------

  bool _hit(Rect r, Offset c, double rad) {
    final nx = c.dx.clamp(r.left, r.right);
    final ny = c.dy.clamp(r.top, r.bottom);
    final dx = c.dx - nx;
    final dy = c.dy - ny;
    return dx * dx + dy * dy <= rad * rad;
  }

  void _checkCollisions() {
    final pc = Offset(player.position.x, player.position.y);
    final pr = player.hitboxRadius;

    // Ceiling clamp.
    if (player.position.y - pr < 0) {
      player.position.y = pr;
      if (player.velocityY < 0) player.velocityY = 0;
    }
    // Ground = death.
    if (player.position.y + pr >= worldHeight - groundHeight) {
      _die();
      return;
    }

    for (final p in _pipePool) {
      if (!p.active) continue;
      if (_hit(p.topRect, pc, pr) || _hit(p.bottomRect, pc, pr)) {
        _die();
        return;
      }
    }
    for (final o in _obstaclePool) {
      if (!o.active) continue;
      if (_hit(o.rect, pc, pr)) {
        _die();
        return;
      }
    }
    // Coin pickups.
    for (final c in _coinPool) {
      if (!c.active) continue;
      final d = (c.position - player.position).length;
      if (d < pr + c.size.x * 0.4) {
        c.recycle();
        controller.addCollectedCoins(c.value);
        sl<AudioService>().playSfx(Sfx.coin);
        sl<VibrationService>().light();
        add(GlowBurst(
          position: c.position.clone(),
          color: c.color,
          count: 8,
          maxSpeed: 120,
        ));
      }
    }
  }

  void _die() {
    if (player.dead) return;
    player.dead = true;
    player.frozen = true;
    sl<AudioService>().playSfx(Sfx.gameOver);
    sl<VibrationService>().heavy();
    add(GlowBurst(
      position: player.position.clone(),
      color: character.primary,
      count: 20,
      maxSpeed: 240,
      radius: 7,
    ));
    _shakeTime = 0.45;
    sl<CoinService>().recordScore(controller.score);
    controller.end();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Keep player horizontally anchored on resize.
    if (playerX > 0) playerX = size.x * 0.28;
  }
}
