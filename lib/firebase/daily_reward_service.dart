import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/firebase/firebase_refs.dart';

/// Snapshot of a player's daily-reward state.
@immutable
class DailyRewardStatus {
  const DailyRewardStatus({
    required this.day,
    required this.streak,
    required this.canClaim,
    required this.rewardCoins,
    required this.lastClaim,
  });

  /// The reward day in the 7-day cycle (1..7).
  final int day;

  /// Consecutive-day streak count.
  final int streak;

  /// Whether a reward can be claimed right now.
  final bool canClaim;

  /// Coins the player receives if they claim today.
  final int rewardCoins;

  final DateTime? lastClaim;
}

/// Handles the daily login reward cycle stored in `daily_rewards/{uid}`.
///
/// Rewards escalate across a 7-day cycle. Missing a day (>2 calendar days since
/// the last claim) resets the streak back to day 1.
class DailyRewardService {
  DailyRewardService(this._refs);

  final FirebaseRefs _refs;

  /// Reward coins for each day of the 7-day cycle.
  static const List<int> cycleRewards = [50, 75, 100, 150, 200, 300, 500];

  int _rewardForDay(int day) {
    final index = (day - 1).clamp(0, cycleRewards.length - 1);
    return cycleRewards[index];
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Reads the current status. Never throws.
  Future<DailyRewardStatus> status(String uid) async {
    try {
      final snap = await _refs.dailyRewards.doc(uid).get();
      final data = snap.data();
      if (data == null) {
        return DailyRewardStatus(
          day: 1,
          streak: 0,
          canClaim: true,
          rewardCoins: _rewardForDay(1),
          lastClaim: null,
        );
      }

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
      final claimedToday = _isSameCalendarDay(lastClaim, now);
      final daysSince = DateTime(now.year, now.month, now.day)
          .difference(DateTime(
              lastClaim.year, lastClaim.month, lastClaim.day))
          .inDays;

      if (claimedToday) {
        return DailyRewardStatus(
          day: storedDay,
          streak: streak,
          canClaim: false,
          rewardCoins: _rewardForDay(storedDay),
          lastClaim: lastClaim,
        );
      }

      // A new claim is available. Determine which day it will be.
      final continues = daysSince == 1;
      final nextDay = continues ? (storedDay % 7) + 1 : 1;
      return DailyRewardStatus(
        day: nextDay,
        streak: continues ? streak : 0,
        canClaim: true,
        rewardCoins: _rewardForDay(nextDay),
        lastClaim: lastClaim,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('DailyRewardService.status failed: $e');
      // Fail closed: no free claim if we cannot verify the state.
      return const DailyRewardStatus(
        day: 1,
        streak: 0,
        canClaim: false,
        rewardCoins: 0,
        lastClaim: null,
      );
    }
  }

  /// Claims today's reward and returns the coins granted (0 if not claimable).
  Future<int> claim(String uid) async {
    final current = await status(uid);
    if (!current.canClaim) return 0;
    final newStreak = current.streak + 1;
    try {
      await _refs.dailyRewards.doc(uid).set({
        'day': current.day,
        'streak': newStreak,
        'lastClaim': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return current.rewardCoins;
    } catch (e) {
      if (kDebugMode) debugPrint('DailyRewardService.claim failed: $e');
      return 0;
    }
  }
}
