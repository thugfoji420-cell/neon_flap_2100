import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/firebase/firebase_refs.dart';

/// Records rewarded ad grant events to Firestore for audit purposes.
///
/// Coin balance is NOT written here — [CoinSyncService] is the sole
/// runtime writer of coin balances. This service only records the reward
/// metadata (reward type, amount, timestamp) so the event is auditable.
class AdRewardService {
  AdRewardService(this._refs);

  final FirebaseRefs _refs;
  final Random _rng = Random();

  /// Records a reward event to Firestore. Returns true on success.
  /// Does NOT write coin balances — those flow through [CoinSyncService].
  Future<bool> grantReward({
    required String uid,
    required int coinAmount,
    required String rewardType,
    required String adUnitId,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final rewardId = '${uid}_${_rng.nextInt(1 << 26)}_$rewardType';

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final playerRef = _refs.player(uid);
        final snapshot = await transaction.get(playerRef);
        final data = snapshot.data() ?? {};

        final history = (data['rewardHistory'] as List<dynamic>?) ?? [];
        history.add({
          'id': rewardId,
          'type': rewardType,
          'adUnitId': adUnitId,
          'coins': coinAmount,
          'timestamp': now,
        });

        transaction.update(playerRef, {
          'rewardHistory': history,
          'lastRewardedAt': now,
        });
      });

      if (kDebugMode) {
        debugPrint('AdRewardService: recorded reward ($rewardType, $coinAmount coins) for $uid');
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('AdRewardService: grant failed: $e');
      return false;
    }
  }
}
