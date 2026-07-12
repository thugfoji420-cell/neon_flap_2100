import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:neon_flap_2100/core/constants/app_constants.dart';
import 'package:neon_flap_2100/models/game_settings.dart';
import 'package:neon_flap_2100/services/storage_service.dart';

/// Holds and persists player settings (volumes, vibration). Exposes a
/// [ChangeNotifier] so the UI and [AudioService] react to changes live.
class SettingsService extends ChangeNotifier {
  SettingsService(this._storage);

  final StorageService _storage;

  GameSettings _settings = const GameSettings();
  GameSettings get settings => _settings;

  /// Load persisted settings; safe to call once at startup.
  Future<void> load() async {
    final raw = _storage.getString(StorageKeys.settings);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _settings = GameSettings.fromJson(map);
      } catch (_) {
        _settings = const GameSettings();
      }
    }
    notifyListeners();
  }

  Future<void> update(GameSettings next) async {
    _settings = next;
    await _storage.setString(StorageKeys.settings, jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  Future<void> setMusicVolume(double v) => update(_settings.copyWith(musicVolume: v));
  Future<void> setSfxVolume(double v) => update(_settings.copyWith(sfxVolume: v));
  Future<void> setVibration(bool v) => update(_settings.copyWith(vibration: v));

  /// Clears all persisted progress (coins, unlocks, best score, settings).
  Future<void> resetProgress(StorageService storage) async {
    await storage.remove(StorageKeys.coins);
    await storage.remove(StorageKeys.bestScore);
    await storage.remove(StorageKeys.unlockedCharacters);
    await storage.remove(StorageKeys.selectedCharacter);
    await storage.remove(StorageKeys.hasSeenAppOpenAd);
    await storage.remove(StorageKeys.pendingRewardedCoins);
    await storage.remove(StorageKeys.playerStats);
    await storage.remove(StorageKeys.achievementProgress);
    await storage.remove(StorageKeys.leaderboard);
    _settings = const GameSettings();
    await storage.setString(StorageKeys.settings, jsonEncode(_settings.toJson()));
    notifyListeners();
  }
}
