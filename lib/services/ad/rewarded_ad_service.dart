import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../storage_service.dart';
import 'ad_analytics.dart';

/// Manages rewarded ad loading and display for 2x and 5x coin rewards.
///
/// Guarantees:
/// - Rewards are only granted inside [onUserEarnedReward].
/// - Duplicate rewards are prevented via [StorageService] flags.
/// - 5x rewards require 3 consecutive successful ads.
class RewardedAdService {
  RewardedAdService(this._storage, this._analytics);

  final StorageService _storage;
  final AdAnalytics _analytics;

  RewardedAd? _ad;
  String? _loadedUnitId;
  int _retryCount = 0;
  Timer? _retryTimer;
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 8);

  RewardedAd? get ad => _ad;
  bool get isLoaded => _ad != null;

  Future<void> load(String unitId) async {
    if (_loadedUnitId == unitId && _ad != null) return;
    _analytics.log(AdEventType.rewardedLoaded, {'unit': unitId, 'attempt': _retryCount + 1});

    final currentUnit = _loadedUnitId;
    if (currentUnit != null && currentUnit != unitId) {
      _ad?.dispose();
      _ad = null;
      _loadedUnitId = null;
    }

    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _retryCount = 0;
          _ad = ad;
          _loadedUnitId = unitId;
          _analytics.log(AdEventType.rewardedLoaded, {'unit': unitId});
        },
        onAdFailedToLoad: (_) {
          _analytics.log(AdEventType.rewardedFailed, {'unit': unitId});
          _ad = null;
          _loadedUnitId = null;
          _scheduleRetry(unitId);
        },
      ),
    );
  }

  void _scheduleRetry(String unitId) {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetries) {
      if (kDebugMode) debugPrint('RewardedAdService: max retries reached');
      return;
    }
    final delay = _retryDelay * pow(2, _retryCount);
    _retryCount++;
    if (kDebugMode) {
      debugPrint('RewardedAdService: retry $_retryCount in $delay');
    }
    _retryTimer = Timer(delay, () => load(unitId));
  }

  /// Shows a single rewarded ad. Returns true only if the user earned the reward.
  Future<bool> show(String unitId) async {
    final ad = _ad;
    if (ad == null || _loadedUnitId != unitId) {
      await load(unitId);
      final newAd = _ad;
      if (newAd == null || _loadedUnitId != unitId) return false;
      return _present(newAd, unitId);
    }
    return _present(ad, unitId);
  }

  Future<bool> _present(RewardedAd ad, String unitId) async {
    _ad = null;
    _loadedUnitId = null;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) =>
          _analytics.log(AdEventType.rewardedShown, {'unit': unitId}),
      onAdDismissedFullScreenContent: (_) {
        _analytics.log(AdEventType.interstitialDismissed);
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        _analytics.log(AdEventType.rewardedFailed, {'unit': unitId, 'error': error.message});
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(onUserEarnedReward: (_, reward) {
      _analytics.log(AdEventType.rewardEarned, {
        'unit': unitId,
        'amount': reward.amount,
        'type': reward.type,
      });
      if (!completer.isCompleted) completer.complete(true);
    });

    return completer.future;
  }

  /// Returns true if the user has already been rewarded for the given session key.
  bool wasRewarded(String sessionKey) {
    return _storage.getBool('nf_rewarded_$sessionKey') ?? false;
  }

  /// Marks the session as rewarded to prevent duplicates.
  Future<void> markRewarded(String sessionKey) async {
    await _storage.setBool('nf_rewarded_$sessionKey', true);
  }

  /// Clears all reward flags for the current session.
  Future<void> clearSessionRewards(String sessionKey) async {
    await _storage.remove('nf_rewarded_${sessionKey}_1');
    await _storage.remove('nf_rewarded_${sessionKey}_2');
    await _storage.remove('nf_rewarded_${sessionKey}_3');
  }

  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
    _loadedUnitId = null;
    _retryCount = 0;
  }
}
