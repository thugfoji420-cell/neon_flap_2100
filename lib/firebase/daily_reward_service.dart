import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/firebase/firebase_refs.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

/// Snapshot of a player's daily-reward state.
@immutable
class DailyRewardStatus {
  const DailyRewardStatus({
    required this.day,
    required this.streak,
    required this.canClaim,
    required this.rewardCoins,
    required this.lastClaim,
    this.remainingMillis = 0,
    this.pendingOffline = false,
  });

  /// The reward day in the 7-day cycle (1..7).
  final int day;

  /// Consecutive-day streak count.
  final int streak;

  /// Whether a reward can be claimed right now.
  final bool canClaim;

  /// Coins the player receives if they claim today.
  final int rewardCoins;

  /// Server (or local) timestamp of the last claim.
  final DateTime? lastClaim;

  /// Milliseconds until the next claim becomes available.
  /// 0 when [canClaim] is true.
  final int remainingMillis;

  /// True when the player claimed offline and the reward hasn't been synced
  /// to Firestore yet.
  final bool pendingOffline;
}

/// Handles the daily login reward cycle stored in `daily_rewards/{uid}` with
/// a true 24-hour cooldown and offline-first local cache.
///
/// Rewards escalate across a 7-day cycle. A 24-hour cooldown is enforced using
/// the Firestore server timestamp as the authoritative clock, with a local
/// SharedPreferences cache as fallback during offline periods.
///
/// **Clock manipulation protection:** On every status check the local cache
/// timestamp is compared against the device clock. If the local timestamp is
/// *ahead* of the current time (beyond a 5-minute tolerance), the clock was
/// moved backward; the local cache is invalidated and the server is re-queried.
///
/// **Offline claim:** When the player is offline and 24+ hours have passed
/// since the last local timestamp, a claim is allowed locally. The reward
/// coins are credited immediately, and a `pendingOffline` flag is set. On the
/// next successful Firestore write the flag is cleared.
class DailyRewardService {
  DailyRewardService(this._refs);

  final FirebaseRefs? _refs;
  static const int _cooldownHours = 24;
  static const int _cooldownMillis = _cooldownHours * 60 * 60 * 1000;
  static const int _clockToleranceMillis = 5 * 60 * 1000; // 5 minutes

  /// Reward coins for each day of the 7-day cycle.
  static const List<int> cycleRewards = [50, 75, 100, 150, 200, 300, 500];

  int _rewardForDay(int day) {
    final index = (day - 1).clamp(0, cycleRewards.length - 1);
    return cycleRewards[index];
  }

  // ---------------------------------------------------------------------------
  // Local cache helpers
  // ---------------------------------------------------------------------------

  StorageService get _storage => sl<StorageService>();

  int? _localLastClaimMillis() =>
      _storage.getInt(StorageKeys.dailyRewardLastClaim);

  Future<void> _saveLocalClaim(int day, int streak) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _storage.setInt(StorageKeys.dailyRewardLastClaim, now);
    await _storage.setInt(StorageKeys.dailyRewardClaimedDay, day);
    await _storage.setInt(StorageKeys.dailyRewardClaimedStreak, streak);
  }

  Future<void> _clearLocal() async {
    await _storage.remove(StorageKeys.dailyRewardLastClaim);
    await _storage.remove(StorageKeys.dailyRewardClaimedDay);
    await _storage.remove(StorageKeys.dailyRewardClaimedStreak);
    await _storage.setBool(StorageKeys.dailyRewardPendingOffline, false);
  }

  /// True if the device clock appears to have been moved backward since the
  /// last claim was recorded locally.
  bool _isClockManipulated(int localMillis) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return localMillis > now + _clockToleranceMillis;
  }

  bool _isPendingOffline() =>
      _storage.getBool(StorageKeys.dailyRewardPendingOffline) ?? false;

  Future<void> _setPendingOffline(bool value) async =>
      _storage.setBool(StorageKeys.dailyRewardPendingOffline, value);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Reads the current status. Uses Firestore as the authoritative source with
  /// local cache as fallback. Never throws.
  Future<DailyRewardStatus> status(String uid) async {
    final refs = _refs;
    if (refs == null) return _computeFromLocal(null);
    // An offline claim has already granted coins locally. Reconcile its exact
    // state before consulting an older cloud record, otherwise that stale
    // record could offer the same reward a second time after reconnect.
    if (_isPendingOffline() && !await _syncPendingClaim(uid)) {
      return _computeFromLocal(null);
    }
    try {
      final snap = await refs.dailyRewards.doc(uid).get();
      final data = snap.data();
      return data != null ? _computeFromServer(data) : _computeFromLocal(null);
    } catch (_) {
      return _computeFromLocal(null);
    }
  }

  /// Writes a previously granted offline claim as absolute state. Retrying
  /// this operation is idempotent, so it cannot advance the reward twice.
  Future<bool> _syncPendingClaim(String uid) async {
    final refs = _refs;
    if (refs == null) return false;
    final localMillis = _localLastClaimMillis();
    if (localMillis == null) {
      await _setPendingOffline(false);
      return true;
    }

    final day = _storage.getInt(StorageKeys.dailyRewardClaimedDay) ?? 1;
    final streak = _storage.getInt(StorageKeys.dailyRewardClaimedStreak) ?? 0;
    try {
      await refs.dailyRewards.doc(uid).set({
        'day': day,
        'streak': streak,
        'lastClaim': Timestamp.fromMillisecondsSinceEpoch(localMillis),
      }, SetOptions(merge: true));
      await _setPendingOffline(false);
      return true;
    } catch (_) {
      return false;
    }
  }

  DailyRewardStatus _computeFromServer(Map<String, dynamic> data) {
    final ts = data['lastClaim'] as Timestamp?;
    final lastClaim = ts?.toDate();
    final streak = (data['streak'] as num?)?.toInt() ?? 0;
    final storedDay = (data['day'] as num?)?.toInt() ?? 1;

    if (lastClaim == null) {
      return DailyRewardStatus(
        day: 1,
        streak: 0,
        canClaim: true,
        rewardCoins: _rewardForDay(1),
        lastClaim: null,
      );
    }

    final now = DateTime.now();
    final elapsed =
        now.millisecondsSinceEpoch - lastClaim.millisecondsSinceEpoch;
    final canClaim = elapsed >= _cooldownMillis;

    if (canClaim) {
      // Determine the next day: if >48h passed, reset to day 1.
      final continues = elapsed < _cooldownMillis * 2;
      final nextDay = continues ? (storedDay % 7) + 1 : 1;
      return DailyRewardStatus(
        day: nextDay,
        streak: continues ? streak : 0,
        canClaim: true,
        rewardCoins: _rewardForDay(nextDay),
        lastClaim: lastClaim,
      );
    }

    final remaining = _cooldownMillis - elapsed;
    return DailyRewardStatus(
      day: storedDay,
      streak: streak,
      canClaim: false,
      rewardCoins: _rewardForDay(storedDay),
      lastClaim: lastClaim,
      remainingMillis: remaining,
    );
  }

  /// Computes status from local cache when Firestore is unreachable.
  DailyRewardStatus _computeFromLocal(Map<String, dynamic>? _) {
    final localMillis = _localLastClaimMillis();

    // No local cache at all → first-time user or data cleared → can claim.
    if (localMillis == null) {
      return DailyRewardStatus(
        day: 1,
        streak: 0,
        canClaim: true,
        rewardCoins: _rewardForDay(1),
        lastClaim: null,
      );
    }

    // Clock manipulation check.
    if (_isClockManipulated(localMillis)) {
      debugPrint('Clock manipulation detected; invalidating local cache.');
      _clearLocal();
      return DailyRewardStatus(
        day: 1,
        streak: 0,
        canClaim: true,
        rewardCoins: _rewardForDay(1),
        lastClaim: null,
      );
    }

    // Check if an offline claim is pending sync.
    if (_isPendingOffline()) {
      final day = _storage.getInt(StorageKeys.dailyRewardClaimedDay) ?? 1;
      final streak = _storage.getInt(StorageKeys.dailyRewardClaimedStreak) ?? 0;
      return DailyRewardStatus(
        day: day,
        streak: streak,
        canClaim: false,
        rewardCoins: _rewardForDay(day),
        lastClaim: DateTime.fromMillisecondsSinceEpoch(localMillis),
        pendingOffline: true,
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - localMillis;
    final canClaim = elapsed >= _cooldownMillis;

    if (canClaim) {
      // Allow an offline claim.
      final storedDay = _storage.getInt(StorageKeys.dailyRewardClaimedDay) ?? 1;
      final streak = _storage.getInt(StorageKeys.dailyRewardClaimedStreak) ?? 0;
      final continues = elapsed < _cooldownMillis * 2;
      final nextDay = continues ? (storedDay % 7) + 1 : 1;
      return DailyRewardStatus(
        day: nextDay,
        streak: continues ? streak : 0,
        canClaim: true,
        rewardCoins: _rewardForDay(nextDay),
        lastClaim: DateTime.fromMillisecondsSinceEpoch(localMillis),
      );
    }

    final remaining = _cooldownMillis - elapsed;
    final storedDay = _storage.getInt(StorageKeys.dailyRewardClaimedDay) ?? 1;
    final streak = _storage.getInt(StorageKeys.dailyRewardClaimedStreak) ?? 0;
    return DailyRewardStatus(
      day: storedDay,
      streak: streak,
      canClaim: false,
      rewardCoins: _rewardForDay(storedDay),
      lastClaim: DateTime.fromMillisecondsSinceEpoch(localMillis),
      remainingMillis: remaining,
    );
  }

  /// Claims today's reward and returns the coins granted.
  ///
  /// - When online: writes to Firestore with server timestamp, saves local cache
  /// - When offline: saves local cache and sets pending offline flag
  /// - Returns 0 if the claim is not yet available
  Future<int> claim(String uid) async {
    final refs = _refs;
    final current = await status(uid);
    if (!current.canClaim) return 0;

    final newStreak = current.streak + 1;

    if (refs == null) {
      await _setPendingOffline(true);
    } else {
      try {
        await refs.dailyRewards.doc(uid).set({
          'day': current.day,
          'streak': newStreak,
          'lastClaim': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // Clear any offline pending flag since we succeeded.
        await _setPendingOffline(false);
      } catch (_) {
        // Firestore write failed (offline). Save locally and flag as pending.
        await _setPendingOffline(true);
      }
    }

    // Always save local cache so offline reads are consistent.
    await _saveLocalClaim(current.day, newStreak);

    return current.rewardCoins;
  }

  Future<DailyRewardStatus> statusLocal() async => _computeFromLocal(null);

  Future<int> claimLocal() async {
    final current = _computeFromLocal(null);
    if (!current.canClaim) return 0;
    await _setPendingOffline(false);
    await _saveLocalClaim(current.day, current.streak + 1);
    return current.rewardCoins;
  }
}
