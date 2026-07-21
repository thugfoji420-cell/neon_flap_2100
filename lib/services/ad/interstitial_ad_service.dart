import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/storage_service.dart';
import 'ad_analytics.dart';
import 'ad_constants.dart';

/// Controls interstitial ad loading and display with frequency capping.
///
/// Frequency rule: maximum 1 interstitial per [gamesBetweenAds] completed games.
class InterstitialAdService {
  InterstitialAdService(this._storage, this._analytics);

  final StorageService _storage;
  final AdAnalytics _analytics;

  static const int gamesBetweenAds = 3;

  InterstitialAd? _ad;
  int _retryCount = 0;
  Timer? _retryTimer;
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 10);

  InterstitialAd? get ad => _ad;
  bool get isLoaded => _ad != null;

  Future<void> load() async {
    if (_ad != null) return;
    _analytics
        .log(AdEventType.interstitialLoaded, {'attempt': _retryCount + 1});

    final unitId = AdConstants.interstitialAdUnitId;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _retryCount = 0;
          _ad = ad;
          _analytics.log(AdEventType.interstitialLoaded);
        },
        onAdFailedToLoad: (_) {
          _analytics.log(AdEventType.interstitialFailed);
          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetries) {
      if (kDebugMode) debugPrint('InterstitialAdService: max retries reached');
      return;
    }
    final delay = _baseRetryDelay * pow(2, _retryCount);
    _retryCount++;
    if (kDebugMode) {
      debugPrint('InterstitialAdService: retry $_retryCount in $delay');
    }
    _retryTimer = Timer(delay, load);
  }

  /// Returns true if the ad was shown, false if frequency-capped or unavailable.
  Future<bool> tryShow() async {
    final ad = _ad;
    if (ad == null) {
      load();
      return false;
    }

    final completed = (_storage.getInt('nf_completed_games') ?? 0);
    final lastShownIndex = (_storage.getInt('nf_last_interstitial_game') ?? -1);
    final gamesSince = completed - lastShownIndex;

    if (gamesSince < gamesBetweenAds) {
      if (kDebugMode) {
        debugPrint(
            'InterstitialAdService: frequency capped ($gamesSince/$gamesBetweenAds games)');
      }
      return false;
    }

    _ad = null;
    await _storage.setInt('nf_last_interstitial_game', completed);
    load();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) =>
          _analytics.log(AdEventType.interstitialShown),
      onAdClicked: (_) => _analytics.log(AdEventType.interstitialClicked),
      onAdDismissedFullScreenContent: (_) {
        _analytics.log(AdEventType.interstitialDismissed);
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _analytics
            .log(AdEventType.interstitialFailed, {'error': error.message});
        ad.dispose();
      },
    );

    await ad.show();
    return true;
  }

  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
    _retryCount = 0;
  }
}
