import 'package:flutter/foundation.dart';
import 'package:neon_flap_2100/core/constants/app_constants.dart';
import 'package:neon_flap_2100/services/storage_service.dart';

/// Owns the player's permanent coin balance and best score.
///
/// All changes are written through [StorageService] immediately so the economy
/// survives app restarts, and a [ChangeNotifier] is exposed for reactive UI.
class CoinService extends ChangeNotifier {
  CoinService(this._storage);

  final StorageService _storage;

  int _coins = 0;
  int _bestScore = 0;

  int get coins => _coins;
  int get bestScore => _bestScore;

  Future<void> load() async {
    _coins = _storage.getInt(StorageKeys.coins) ?? 0;
    _bestScore = _storage.getInt(StorageKeys.bestScore) ?? 0;
    notifyListeners();
  }

  /// Adds coins to the balance (never negative).
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    await _storage.setInt(StorageKeys.coins, _coins);
    notifyListeners();
  }

  /// Attempts to spend coins. Returns false (and changes nothing) if the
  /// balance is insufficient.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    await _storage.setInt(StorageKeys.coins, _coins);
    notifyListeners();
    return true;
  }

  /// Records a finished run's score, updating the best score if beaten.
  Future<void> recordScore(int score) async {
    if (score > _bestScore) {
      _bestScore = score;
      await _storage.setInt(StorageKeys.bestScore, _bestScore);
      notifyListeners();
    }
  }
}
