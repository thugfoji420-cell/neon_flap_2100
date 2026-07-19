import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/services/ad/ad_analytics.dart';
import 'package:neon_flap1_game/services/ad/ad_constants.dart';
import 'package:neon_flap1_game/services/ad/app_open_ad_service.dart';
import 'package:neon_flap1_game/services/ad/interstitial_ad_service.dart';
import 'package:neon_flap1_game/services/ad/rewarded_ad_service.dart';
import 'package:neon_flap1_game/firebase/ad_reward_service.dart';

/// Facade composing all ad services. Banner ads are managed independently by
/// [BannerAdSlot] widgets and are not part of this service.
class AdService extends ChangeNotifier {
  AdService(
    this._analytics,
    this._interstitial,
    this._appOpen,
    this._rewarded,
    this._rewardSync,
  );

  final AdAnalytics _analytics;
  final InterstitialAdService _interstitial;
  final AppOpenAdService _appOpen;
  final RewardedAdService _rewarded;
  final AdRewardService _rewardSync;

  bool _initialized = false;

  /// Must be called once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    _analytics.log(AdEventType.adInit, {
      'mode': AdConstants.isDebug ? 'debug' : 'release',
    });

    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: <String>[
          'EMULATOR',
          '2AA02B5D374E70B1F1EDD9B4489D84B8',
        ],
      ),
    );

    await _interstitial.load();
    await _appOpen.load();
    await _rewarded.load(AdConstants.rewardedAdUnitId2x);
    await _rewarded.load(AdConstants.rewardedAdUnitId5x);

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // App Open Ad
  // ---------------------------------------------------------------------------

  bool get isAppOpenAdLoaded => _appOpen.isLoaded;

  Future<void> maybeShowAppOpenAd({Future<void> Function()? onComplete}) async {
    try {
      await _appOpen.tryShow();
    } catch (_) {
      // ignore show failures
    }
    try {
      await onComplete?.call();
    } catch (_) {
      // ignore callback failures
    }
  }

  // ---------------------------------------------------------------------------
  // Interstitial Ad
  // ---------------------------------------------------------------------------

  void loadInterstitialAd() => _interstitial.load();

  Future<bool> showInterstitialAd({VoidCallback? onComplete}) async {
    final shown = await _interstitial.tryShow();
    onComplete?.call();
    return shown;
  }

  // ---------------------------------------------------------------------------
  // Rewarded Ad
  // ---------------------------------------------------------------------------

  bool get isRewardedReady => _rewarded.isLoaded;

  void showRewardedAd({
    required void Function(RewardItem reward) onEarnedReward,
    required VoidCallback onComplete,
    String? adUnitId,
  }) {
    final unitId = adUnitId ?? AdConstants.rewardedAdUnitId2x;
    _rewarded.load(unitId);
    _rewarded.show(unitId).then((earned) {
      if (earned) onEarnedReward(RewardItem(1, 'reward'));
      onComplete();
    });
  }

  // ---------------------------------------------------------------------------
  // Reward persistence helpers
  // ---------------------------------------------------------------------------

  Future<bool> grantReward({
    required int coinAmount,
    required String rewardType,
    required String adUnitId,
  }) async {
    final uid = sl<FirebaseService>().uid;
    if (uid == null) return false;
    return _rewardSync.grantReward(
      uid: uid,
      coinAmount: coinAmount,
      rewardType: rewardType,
      adUnitId: adUnitId,
    );
  }

  bool wasRewarded(String sessionKey) => _rewarded.wasRewarded(sessionKey);

  Future<void> markRewarded(String sessionKey) =>
      _rewarded.markRewarded(sessionKey);

  Future<void> clearSessionRewards(String sessionKey) =>
      _rewarded.clearSessionRewards(sessionKey);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _interstitial.dispose();
    _appOpen.dispose();
    _rewarded.dispose();
    super.dispose();
  }
}
