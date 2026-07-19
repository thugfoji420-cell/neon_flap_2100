import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/models/difficulty_config.dart';

/// Lifecycle phase of a single play session.
enum GamePhase { ready, countdown, playing, gameOver }

/// Reactive state for the active run. The Flame game writes to it; the HUD and
/// screens read from it. Kept deliberately small to avoid per-frame churn.
class GameController extends ChangeNotifier {
  GameController();

  int score = 0;
  int collectedCoins = 0;
  int totalFlaps = 0;
  double _scoreCoinAccum = 0.0;

  GamePhase phase = GamePhase.ready;
  DifficultyConfig? config;

  /// Coins earned this run (score-derived + collected), rounded for display.
  int get earnedCoins => (collectedCoins + _scoreCoinAccum).round();

  void reset(DifficultyConfig cfg) {
    score = 0;
    collectedCoins = 0;
    totalFlaps = 0;
    _scoreCoinAccum = 0.0;
    config = cfg;
    phase = GamePhase.ready;
    notifyListeners();
  }

  void startCountdown() {
    phase = GamePhase.countdown;
    notifyListeners();
  }

  void beginPlay() {
    phase = GamePhase.playing;
    notifyListeners();
  }

  void addScore() {
    score++;
    _scoreCoinAccum += config?.coinPerScore ?? 0;
    notifyListeners();
  }

  void addFlap() {
    totalFlaps++;
  }

  void addCollectedCoins(int value) {
    collectedCoins += value;
    notifyListeners();
  }

  void end() {
    if (phase == GamePhase.gameOver) return;
    phase = GamePhase.gameOver;
    notifyListeners();
  }
}
