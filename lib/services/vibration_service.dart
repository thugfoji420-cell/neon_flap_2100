import 'package:flutter/services.dart';

import 'package:neon_flap1_game/services/settings_service.dart';

/// Thin wrapper around [HapticFeedback] that respects the player's vibration
/// setting. Used for taps, coin pickups, unlocks and crashes.
class VibrationService {
  VibrationService(this._settings);

  final SettingsService _settings;

  void light() {
    if (_settings.settings.vibration) HapticFeedback.lightImpact();
  }

  void medium() {
    if (_settings.settings.vibration) HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (_settings.settings.vibration) HapticFeedback.heavyImpact();
  }

  void selection() {
    if (_settings.settings.vibration) HapticFeedback.selectionClick();
  }
}
