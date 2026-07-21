import 'dart:async';
import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/characters/character_sprite_catalog.dart';
import 'package:neon_flap1_game/core/constants/game_constants.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/game/components/background.dart';
import 'package:neon_flap1_game/game/components/coin.dart';
import 'package:neon_flap1_game/game/components/glow_particle.dart';
import 'package:neon_flap1_game/game/components/obstacle.dart';
import 'package:neon_flap1_game/game/components/player.dart';
import 'package:neon_flap1_game/game/components/pipes.dart';
import 'package:neon_flap1_game/game/game_controller.dart';
import 'package:neon_flap1_game/game/pipe_gap_planner.dart';
import 'package:neon_flap1_game/models/character.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/difficulty_service.dart';
import 'package:neon_flap1_game/services/vibration_service.dart';

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

  Player? player;
  CityBackground? bg;
  Ground? ground;
  final Vector2 _canvasSize = Vector2.zero();

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
  int _activePipeCount = 0;
  final Random _rnd = Random();
  final PipeGapPlanner _gapPlanner = PipeGapPlanner();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Zooming the actual camera viewfinder expands the visible world without
    // changing gameplay physics, speed, pipe spacing or player size.
    camera.viewfinder.zoom = GameConstants.viewZoom;
    _gapPlanner.reset();

    // Position the player at ~22% from the left edge so ~78% of the visible
    // world is ahead, clearly showing approximately two upcoming pipe gaps.
    playerX = size.x * 0.22;
    groundHeight = max(30, size.y * 0.06);

    // The camera is zoomed out (see above), so the visible world is larger than
    // the raw screen [size]. Draw the background/ground across the FULL visible
    // area (size / zoom) so nothing is left blank where upcoming pipes appear.
    _rebuildWorldDecor(size / GameConstants.viewZoom);

    // Decode the selected six-frame sheet before the round becomes playable.
    // The same cache is shared with Flutter's shop and main-menu preview.
    try {
      await CharacterSpriteCache.preload(character.id);
    } catch (error) {
      debugPrint('Unable to preload character sprite ${character.id}: $error');
    }

    player = Player(character: character);
    final p = player!;
    p.position = Vector2(playerX, size.y * 0.45);
    p.frozen = true;
    add(p);

    // ground and bg are guaranteed non-null here — set by _rebuildWorldDecor
    // on the synchronous call above.
    add(ground!);

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
    _loadCompleter.complete();
  }

  final Completer<void> _loadCompleter = Completer<void>();
  Future<void> get loadFuture => _loadCompleter.future;

  /// Tap / input handler invoked by the UI.
  void flap() {
    final p = player;
    if (controller.phase != GamePhase.playing || p == null || p.dead) return;
    p.flap();
    controller.addFlap();
    sl<AudioService>().playSfx(Sfx.tap);
    sl<VibrationService>().selection();
  }

  void startPlay() {
    final p = player;
    if (p == null) return;
    p.frozen = false;
    controller.beginPlay();
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

    // bg and ground are non-null after onLoad() completes. The game loop only
    // runs after onLoad(), so these are mathematically safe.
    bg!.advance(_speed, dt);
    ground!.advance(_speed, dt);

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
      camera.viewfinder.position = Vector2(sin(t * 1.7) * 9, cos(t * 2.3) * 9);
    } else if (camera.viewfinder.position.length > 0.001) {
      camera.viewfinder.position = Vector2.zero();
    }
  }

  void _updatePipes(double dt) {
    _activePipeCount = 0;
    for (final pipe in _pipePool) {
      if (!pipe.active) continue;
      _activePipeCount++;
      pipe.update(dt);
      if (!pipe.passed && pipe.rightEdge < playerX) {
        pipe.passed = true;
        controller.addScore();
      }
      if (pipe.position.x + GameConstants.pipeWidth < -20) pipe.recycle();
    }
  }

  void _updateCoins(double dt) {
    final p = player;
    if (p == null) return;
    final attractR = 24 + 70 * character.stats.coinAttraction;
    for (final c in _coinPool) {
      if (!c.active) continue;
      // Magnet: pull nearby coins toward the player.
      final dist = (c.position - p.position).length;
      if (dist < attractR) {
        final f = (dt * (1 - dist / attractR) * 6).clamp(0.0, 1.0);
        c.magnetize(p.position, f);
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
    for (final pipe in _pipePool) {
      if (!pipe.active) return pipe;
    }
    return null;
  }

  Coin? _acquireCoin() {
    for (final c in _coinPool) {
      if (!c.active) return c;
    }
    return null;
  }

  int _activeCoinCount() {
    var count = 0;
    for (final coin in _coinPool) {
      if (coin.active) count++;
    }
    return count;
  }

  Obstacle? _acquireObstacle() {
    for (final o in _obstaclePool) {
      if (!o.active) return o;
    }
    return null;
  }

  void _maybeSpawn() {
    // Spawn a new pipe when no active pipe has crossed the spawn threshold.
    // Uses _activePipeCount (tracked in _updatePipes) to avoid scanning the
    // full pool — only check active pipes for the rightmost position.
    if (_activePipeCount >= GameConstants.maxPipePool) return;
    var rightmost = -double.infinity;
    for (final pipe in _pipePool) {
      if (!pipe.active) continue;
      if (pipe.position.x > rightmost) rightmost = pipe.position.x;
    }
    if (rightmost > size.x - GameConstants.pipeSpacing) return;

    final color =
        NeonPalette.pipeCycle[_colorIndex++ % NeonPalette.pipeCycle.length];
    final score = controller.score;
    // Preserve a full player-sized safety buffer at both walls before asking
    // the planner for a randomized vertical opening. This handles every
    // Android aspect ratio without generating an impossible gap.
    final topClearance = max(44.0, worldHeight * 0.09).toDouble();
    final bottomClearance = max(28.0, worldHeight * 0.05).toDouble();
    final playableHeight =
        worldHeight - groundHeight - topClearance - bottomClearance;
    final maxFairGap = playableHeight - GameConstants.playerSize * 2.4;
    if (maxFairGap < GameConstants.playerSize * 2.6) return;
    final gap = min(_currentGap, maxFairGap);
    final minY = topClearance + gap / 2;
    final maxY = worldHeight - groundHeight - bottomClearance - gap / 2;
    final centerY = _gapPlanner.nextCenter(
      minCenter: minY,
      maxCenter: maxY,
      score: score,
      config: difficulty.config,
    );

    final pipe = _acquirePipe();
    if (pipe == null) return;
    final motionPhase = _rnd.nextDouble() * pi * 2;
    pipe.spawn(
      x: size.x + GameConstants.pipeWidth,
      centerY: centerY,
      gap: gap,
      speed: _speed,
      worldHeight: worldHeight,
      color: color,
      motion: difficulty.config.pipeMotion,
      minCenterY: minY,
      maxCenterY: maxY,
      motionPhase: motionPhase,
    );

    // Coins ride through the gap for satisfying collection lines.
    final coinConfig = difficulty.config.coinSpawn;
    final activeCoins = _activeCoinCount();
    final remainingCoins = coinConfig.maxActiveCoins - activeCoins;
    if (remainingCoins > 0 && _rnd.nextDouble() < coinConfig.spawnChance) {
      final clusterMax = min(coinConfig.maxCoins, remainingCoins);
      final clusterMin = min(coinConfig.minCoins, clusterMax);
      final coinCount = clusterMin + _rnd.nextInt(clusterMax - clusterMin + 1);
      final coinX = size.x + GameConstants.pipeWidth + 30;
      for (var i = 0; i < coinCount; i++) {
        final coin = _acquireCoin();
        if (coin == null) break;
        coin.spawn(
          position: Vector2(
            coinX + i * 40,
            pipe.baseCenterY,
          ),
          speed: _speed,
          motionAmplitude: pipe.motionAmplitude,
          motionSpeed: pipe.motionSpeed,
          motionPhase: pipe.motionPhase,
        );
      }
    }

    // Optional obstacle stays completely inside a pipe wall, including its
    // animation range, so it can never reduce a generated fair opening.
    final freq = difficulty.config.obstacleFrequencyForScore(score);
    if (freq > 0 && _rnd.nextDouble() < freq) {
      final obs = _acquireObstacle();
      if (obs != null) {
        final isHazard = difficulty.config.hazards && _rnd.nextDouble() < 0.5;
        final obstacleHalf = GameConstants.obstacleSize / 2;
        final amplitude = isHazard ? 22.0 : 28.0;
        final topWallBottom = centerY - gap / 2;
        final bottomWallTop = centerY + gap / 2;
        final playfieldBottom = worldHeight - groundHeight;
        final topFits = topWallBottom >= (obstacleHalf + amplitude) * 2;
        final bottomFits =
            playfieldBottom - bottomWallTop >= (obstacleHalf + amplitude) * 2;
        if (!topFits && !bottomFits) return;
        final inTop = topFits && (!bottomFits || _rnd.nextBool());
        final wallY =
            inTop ? topWallBottom / 2 : (bottomWallTop + playfieldBottom) / 2;
        final obSpeed = isHazard
            ? difficulty.config.obstacleSpeedForScore(score) * 1.8
            : difficulty.config.obstacleSpeedForScore(score);
        obs.spawn(
          x: size.x + GameConstants.pipeWidth + 20,
          baseY: wallY,
          amplitude: amplitude,
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
    final p = player;
    if (p == null || p.dead) return;
    final pc = Offset(p.position.x, p.position.y);
    final pr = p.hitboxRadius;

    // Ceiling clamp.
    if (p.position.y - pr < 0) {
      p.position.y = pr;
      if (p.velocityY < 0) p.velocityY = 0;
    }
    // Ground = death.
    if (p.position.y + pr >= worldHeight - groundHeight) {
      _die();
      return;
    }

    for (final pipe in _pipePool) {
      if (!pipe.active) continue;
      if (_hit(pipe.topRect, pc, pr) || _hit(pipe.bottomRect, pc, pr)) {
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
    // Coin pickups — p is captured from the guard above.
    for (final c in _coinPool) {
      if (!c.active) continue;
      final d = (c.position - p.position).length;
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
    final p = player;
    if (p == null || p.dead) return;
    p.dead = true;
    p.frozen = true;
    sl<AudioService>().playSfx(Sfx.gameOver);
    sl<VibrationService>().heavy();
    add(GlowBurst(
      position: p.position.clone(),
      color: character.primary,
      count: 20,
      maxSpeed: 240,
      radius: 7,
    ));
    _shakeTime = 0.45;
    // Credit the base earned coins immediately so they survive regardless of ad
    // choice. The reward screen only adds the bonus multiplier portion.
    sl<CoinService>().addCoins(controller.earnedCoins);
    sl<CoinService>().recordScore(controller.score);
    controller.end();
  }

  @override
  void onGameResize(Vector2 size) {
    // Skip rebuild if dimensions are unchanged — prevents destroying and
    // recreating the background/ground on every layout pass (e.g. during
    // initial widget mount which can fire resize multiple times).
    if (size.x == _canvasSize.x && size.y == _canvasSize.y) return;
    _canvasSize.setFrom(size);
    super.onGameResize(size);
    // Keep the zoomed-out camera on resize.
    camera.viewfinder.zoom = GameConstants.viewZoom;
    // Rebuild the decor so it always covers the full visible world width.
    _rebuildWorldDecor(size / GameConstants.viewZoom);
    // Keep player horizontally anchored on resize.
    if (playerX > 0) playerX = size.x * 0.22;
  }

  /// (Re)creates the background and ground at [viewSize] so they always span
  /// the full zoomed-out visible area, even after an orientation/resize change.
  void _rebuildWorldDecor(Vector2 viewSize) {
    // The null check + immediate null + reassign + use pattern below is safe
    // because there is no async gap or re-entrancy in this synchronous method.
    if (bg != null) {
      bg!.removeFromParent();
      bg = null;
    }
    if (ground != null) {
      ground!.removeFromParent();
      ground = null;
    }
    bg = CityBackground(worldSize: viewSize);
    ground = Ground(worldSize: viewSize, height: groundHeight);
    // bg and ground were just assigned on the lines above — guaranteed non-null.
    add(bg!);
    add(ground!);
  }
}
