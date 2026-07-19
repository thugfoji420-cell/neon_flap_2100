import 'package:flutter/foundation.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

/// Owns the player's permanent coin balance and best score.
///
/// All changes are written through [StorageService] IMMEDIATELY so the economy
/// survives app restarts, and a [ChangeNotifier] is exposed for reactive UI.
///
/// Threading of cloud synchronisation is delegated to [CoinSyncService]: every
/// mutation here updates the in-memory total + persisted total and notifies
/// listeners, and the sync service then reliably pushes the authoritative total
/// to Firestore (with offline queueing and automatic retry), guaranteeing coins
/// are never duplicated or lost.
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

  /// Persists the authoritative [total] atomically. SharedPreferences writes are
  /// atomic, so a crash between the in-memory update and this never leaves a
  /// torn value, and we never *add* to storage (which would risk double
  /// counting) — we always overwrite the whole total.
  Future<void> _persist(int total) async {
    _coins = total;
    await _storage.setInt(StorageKeys.coins, total);
    notifyListeners();
  }

  /// Adds coins to the balance (never negative).
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    await _persist(_coins + amount);
  }

  /// Attempts to spend coins. Returns false (and changes nothing) if the
  /// balance is insufficient.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    await _persist(_coins - amount);
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

  /// Adopt a cloud value (used during Firebase bootstrap). Does not notify
  /// listeners a second time because the caller chains these in setup.
  Future<void> setFromCloud(int value) async {
    if (value == _coins) return;
    await _persist(value);
  }

  Future<void> setBestScoreFromCloud(int value) async {
    if (value == _bestScore) return;
    _bestScore = value;
    await _storage.setInt(StorageKeys.bestScore, _bestScore);
    notifyListeners();
  }
}
