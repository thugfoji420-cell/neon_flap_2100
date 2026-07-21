import 'dart:async';
import 'dart:math';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

/// Professional coin persistence + cloud-sync layer.
///
/// Single source of truth is [CoinService] (in-memory total, mirrored to
/// SharedPreferences). This service owns the *cloud* leg of the pipeline and is
/// built to guarantee coins are never duplicated or lost:
///
///   Collect Coin → [CoinService] updates memory + local storage immediately
///                → [CoinSyncService] queues the new authoritative total
///                → flushed to Firestore (latest-wins, single in-flight write)
///                → if offline, retried with exponential backoff
///                → flushed again automatically when connectivity returns.
///
/// Only the LATEST total is ever written (we never add deltas to the cloud),
/// so a crash, restart or double event can never double-count. A locally
/// persisted pending total means an interrupted flush resumes on next launch.
class CoinSyncService {
  CoinSyncService(this._storage);

  final StorageService _storage;

  /// Authoritative total awaiting the next (or an in-progress) cloud write.
  int _pendingTotal = 0;
  bool _hasPending = false;

  /// True while a cloud write is in flight, so we never run two writes at once.
  bool _inFlight = false;

  /// Backoff timer for the next retry after a failed/network write.
  Timer? _retryTimer;
  int _consecutiveFails = 0;
  bool _attached = false;

  /// Wires this service to the [CoinService] listener. Called once at startup.
  void attach() {
    if (_attached) return;
    try {
      if (sl<FirebaseService>().isOfflineGuest) return;
    } catch (_) {
      return;
    }
    _attached = true;
    final coins = sl<CoinService>();
    // Replay anything left from a previous session that never reached the cloud.
    _pendingTotal =
        _storage.getInt(StorageKeys.pendingCloudCoins) ?? coins.coins;
    _hasPending =
        _pendingTotal != coins.coins || _storage.getBool(_pendingFlag) == true;
    _storage.setBool(_pendingFlag, _hasPending);
    coins.addListener(_onCoinsChanged);
    _onCoinsChanged();
  }

  /// Removes the [CoinService] listener and cancels any pending retry. Safe to
  /// call on every [CoinSyncService] lifecycle end (e.g. hot restart).
  void detach() {
    if (!_attached) return;
    _attached = false;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      sl<CoinService>().removeListener(_onCoinsChanged);
    } catch (_) {
      // Service locator may have been cleared.
    }
  }

  /// Stops writes from the previous account and clears its persisted journal
  /// before another Google account can authenticate on this device.
  Future<void> resetForAccountChange() async {
    detach();
    _pendingTotal = 0;
    _hasPending = false;
    _consecutiveFails = 0;
    await _storage.remove(StorageKeys.pendingCloudCoins);
    await _storage.setBool(_pendingFlag, false);
  }

  static const String _pendingFlag = 'nf_coin_sync_pending';

  /// Debounce timer for SharedPreferences writes during rapid coin bursts
  /// (e.g. collecting 3 coins in quick succession). Only the latest total is
  /// persisted after [_debounceDelay] of inactivity.
  Timer? _debounceTimer;
  static const _debounceDelay = Duration(milliseconds: 150);

  void _onCoinsChanged() {
    if (!_attached) return;
    final firebase = sl<FirebaseService>();
    if (firebase.isOfflineGuest) {
      _hasPending = false;
      _retryTimer?.cancel();
      _storage.setBool(_pendingFlag, false);
      _storage.remove(StorageKeys.pendingCloudCoins);
      return;
    }
    final total = sl<CoinService>().coins;
    _pendingTotal = total;
    _hasPending = true;
    // Debounce SharedPreferences writes: during a coin burst (e.g. 3 coins in
    // succession) only the final total is persisted, avoiding 3+ sequential
    // I/O calls per frame.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      _storage.setInt(StorageKeys.pendingCloudCoins, total);
      _storage.setBool(_pendingFlag, true);
    });
    _scheduleFlush();
  }

  /// Force a flush (e.g. when the app returns from the background or the OS
  /// reports connectivity). Safe to call repeatedly.
  void flushNow() => _scheduleFlush(immediate: true);

  void _scheduleFlush({bool immediate = false}) {
    if (!_attached) return;
    _retryTimer?.cancel();
    if (_inFlight) return;
    final delay = immediate ? Duration.zero : _backoff();
    if (delay == Duration.zero) {
      _flush();
    } else {
      _retryTimer = Timer(delay, _flush);
    }
  }

  Duration _backoff() {
    // 0.5s, 1s, 2s, 4s, 8s ... capped at 15s.
    final seconds = min(15, pow(2, _consecutiveFails).toDouble() * 0.5);
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Future<void> _flush() async {
    if (!_attached || _inFlight || !_hasPending) return;
    final firebase = sl<FirebaseService>();
    if (firebase.isOfflineGuest) {
      _hasPending = false;
      _consecutiveFails = 0;
      await _storage.setBool(_pendingFlag, false);
      await _storage.remove(StorageKeys.pendingCloudCoins);
      return;
    }
    final uid = firebase.uid;
    if (uid == null) {
      // Not signed in yet (e.g. still bootstrapping). Keep pending + retry.
      _consecutiveFails++;
      _scheduleFlush();
      return;
    }

    _inFlight = true;
    final total = _pendingTotal;
    final best = sl<CoinService>().bestScore;
    try {
      await firebase.syncCoins(total);
      // The first write captured the previous profile before its await. Do not
      // let a completion after logout write the stale total to a newly signed-
      // in account's cloud-save document.
      if (!_attached || firebase.uid != uid) return;
      await firebase.player.syncCloudSave(coins: total, highScore: best);
      if (!_attached || firebase.uid != uid) return;
      // Success: clear the pending journal.
      _hasPending = false;
      _consecutiveFails = 0;
      await _storage.setBool(_pendingFlag, false);
      await _storage.remove(StorageKeys.pendingCloudCoins);
    } catch (_) {
      // Offline or network error: keep the pending total and retry.
      _consecutiveFails++;
      _scheduleFlush();
    } finally {
      _inFlight = false;
      if (_attached && _hasPending) {
        _scheduleFlush(immediate: true);
      }
    }
  }

  /// Should be called from the app lifecycle so a return-from-background or a
  /// regained connection immediately pushes any pending total to the cloud.
  void onConnectivityRestored() {
    _consecutiveFails = 0;
    _scheduleFlush(immediate: true);
  }

  void dispose() {
    detach();
  }
}
