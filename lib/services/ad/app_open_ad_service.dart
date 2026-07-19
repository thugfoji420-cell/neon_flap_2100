import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_analytics.dart';
import 'ad_constants.dart';

/// Manages App Open ads. Shows only on cold start, preloads next after dismissal.
class AppOpenAdService {
  AppOpenAdService(this._analytics);

  final AdAnalytics _analytics;

  AppOpenAd? _ad;
  int _retryCount = 0;
  Timer? _retryTimer;
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 15);

  AppOpenAd? get ad => _ad;
  bool get isLoaded => _ad != null;

  Future<void> load() async {
    if (_ad != null) return;
    _analytics.log(AdEventType.appOpenLoaded, {'attempt': _retryCount + 1});

    final unitId = AdConstants.appOpenAdUnitId;
    AppOpenAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _retryCount = 0;
          _ad = ad;
          _analytics.log(AdEventType.appOpenLoaded);
        },
        onAdFailedToLoad: (_) {
          _analytics.log(AdEventType.appOpenFailed);
          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetries) {
      if (kDebugMode) debugPrint('AppOpenAdService: max retries reached');
      return;
    }
    final delay = _baseRetryDelay * pow(2, _retryCount);
    _retryCount++;
    if (kDebugMode) {
      debugPrint('AppOpenAdService: retry $_retryCount in $delay');
    }
    _retryTimer = Timer(delay, load);
  }

  Future<void> tryShow() async {
    final ad = _ad;
    if (ad == null) return;

    _ad = null;
    load();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) =>
          _analytics.log(AdEventType.appOpenShown),
      onAdDismissedFullScreenContent: (_) {
        _analytics.log(AdEventType.appOpenDismissed);
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _analytics.log(AdEventType.appOpenFailed, {'error': error.message});
        ad.dispose();
      },
    );

    await ad.show();
  }

  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
    _retryCount = 0;
  }
}
