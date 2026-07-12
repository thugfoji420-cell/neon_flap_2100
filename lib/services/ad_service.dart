import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:neon_flap_2100/core/constants/app_constants.dart';

/// Wraps Google Mobile Ads.
///
/// * App Open Ads are shown at startup every time the app opens if loaded.
/// * Banner Ads are loaded on demand and displayed only during gameplay.
/// * Rewarded Ads drive the reward screen; rewards are only granted inside
///   [showRewardedAd]'s [onEarnedReward] callback (after the user earns it).
/// * Interstitial Ads are shown when returning to the main menu from a game.
///
/// Test ad unit ids from [AppConstants] are used in debug builds.
class AdService extends ChangeNotifier {
  AdService();

  AppOpenAd? _appOpenAd;

  BannerAd? bannerAd;
  bool _bannerLoaded = false;
  bool get isBannerLoaded => _bannerLoaded;

  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;
  bool get isRewardedReady => _rewardedAd != null;
  String? _currentRewardedAdUnitId;

  InterstitialAd? _interstitialAd;
  DateTime? _lastInterstitialTime;

  /// Must be called once before any ad operation.
  Future<void> init() async {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        // Only the emulator is forced to test ads. Real devices serve live ads.
        testDeviceIds: <String>['EMULATOR'],
      ),
    );
    _loadAppOpenAd();
  }

  // ---------------------------------------------------------------------------
  // App Open Ad
  // ---------------------------------------------------------------------------

  void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: AppConstants.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (_) => _appOpenAd = null,
      ),
    );
  }

  /// Shows the app open ad if it is already loaded.
  /// If not loaded it returns immediately (and [onComplete]
  /// fires at once) so the caller can proceed straight to the main menu.
  bool get isAppOpenAdLoaded => _appOpenAd != null;

  void maybeShowAppOpenAd({VoidCallback? onComplete}) {
    final ad = _appOpenAd;
    if (ad == null) {
      onComplete?.call(); // Unavailable: continue immediately.
      return;
    }
    _appOpenAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (d) {
        d.dispose();
        _loadAppOpenAd();
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (d, _) {
        d.dispose();
        _loadAppOpenAd();
        onComplete?.call();
      },
    );
    ad.show();
  }

  // ---------------------------------------------------------------------------
  // Interstitial Ad
  // ---------------------------------------------------------------------------

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// Shows an interstitial ad if available and not shown recently.
  /// Returns true if an ad was shown, false otherwise.
  Future<bool> showInterstitialAd({VoidCallback? onComplete}) async {
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitialAd();
      onComplete?.call();
      return false;
    }

    final now = DateTime.now();
    if (_lastInterstitialTime != null &&
        now.difference(_lastInterstitialTime!).inSeconds < 5) {
      onComplete?.call();
      return false;
    }

    _interstitialAd = null;
    _lastInterstitialTime = now;
    _loadInterstitialAd();

    await ad.show();
    onComplete?.call();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Banner Ad
  // ---------------------------------------------------------------------------

  void loadBanner() {
    if (bannerAd != null) return;
    bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          bannerAd = null;
          _bannerLoaded = false;
        },
      ),
    )..load();
  }

  void disposeBanner() {
    bannerAd?.dispose();
    bannerAd = null;
    _bannerLoaded = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Rewarded Ad
  // ---------------------------------------------------------------------------

  /// Loads (if needed) and shows a single rewarded ad.
  ///
  /// [onEarnedReward] fires only after the user actually earns the reward.
  /// [onComplete] always fires when the ad flow ends (success or failure) so
  /// the reward screen can advance regardless.
  /// [adUnitId] allows overriding the default rewarded ad unit.
  void showRewardedAd({
    required void Function(RewardItem reward) onEarnedReward,
    required VoidCallback onComplete,
    String? adUnitId,
  }) {
    final unitId = adUnitId ?? AppConstants.rewardedAdUnitId;
    final show = (RewardedAd ad) {
      _rewardedAd = null;
      _currentRewardedAdUnitId = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (d) {
          d.dispose();
          _rewardedLoading = false;
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (d, _) {
          d.dispose();
          _rewardedLoading = false;
          onComplete();
        },
      );
      ad.setImmersiveMode(true);
      ad.show(onUserEarnedReward: (_, reward) => onEarnedReward(reward));
    };

    if (_rewardedAd != null && _currentRewardedAdUnitId == unitId) {
      show(_rewardedAd!);
      return;
    }
    if (_rewardedLoading) return;
    _rewardedLoading = true;
    _currentRewardedAdUnitId = unitId;
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          show(ad);
        },
        onAdFailedToLoad: (_) {
          _rewardedLoading = false;
          _currentRewardedAdUnitId = null;
          onComplete();
        },
      ),
    );
  }

  @override
  void dispose() {
    _appOpenAd?.dispose();
    disposeBanner();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
