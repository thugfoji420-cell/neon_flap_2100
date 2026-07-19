import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

/// Holds the user's selected appearance and persists it through
/// [SharedPreferences] via [StorageService].
class ThemeController extends ChangeNotifier {
  ThemeController(this._storage);

  final StorageService _storage;
  ThemeMode _themeMode = ThemeMode.system;

  /// Defaults to the device setting until the player explicitly chooses one.
  ThemeMode get themeMode => _themeMode;

  /// Restores the saved mode without blocking the first app frame.
  Future<void> load() async {
    final savedMode = _storage.getString(StorageKeys.themeMode);
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  /// Applies and saves a new mode immediately, allowing MaterialApp to animate
  /// the theme transition without restarting the game.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.setString(StorageKeys.themeMode, mode.name);
  }
}
