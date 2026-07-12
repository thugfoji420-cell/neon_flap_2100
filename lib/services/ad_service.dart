import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:neon_flap_2100/core/constants/app_constants.dart';

/// Wraps Google Mobile Ads.
///
/// * App Open Ads are shown at most once per app session, only on the
///   splash -> main menu transition (never during gameplay).
/// * Banner Ads are loaded on demand and displayed only during gameplay.
/// * Rewarded Ads drive the reward screen; rewards are only granted inside
///   [showRewardedAd]'s [onEarnedReward] callback (after the user earns it).
///
/// Test ad unit ids from [AppConstants] are used in debug builds.
class AdService extends ChangeNotifier {
  AdService();

  AppOpenAd? _appOpenAd;
  bool _appOpenShownThisSession = false;

  BannerAd? bannerAd;
  bool _bannerLoaded = false;
  bool get isBannerLoaded => _bannerLoaded;

  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;
  bool get isRewardedReady => _rewardedAd != null;

  /// Must be called once before any ad operation.
  Future<void> init() async {
    await MobileAds.instance.initialize();
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

  /// Shows the app open ad once per session if it is already loaded.
  /// If not loaded (or already shown) it returns immediately (and [onComplete]
  /// fires at once) so the caller can proceed straight to the main menu.
  void maybeShowAppOpenAd({VoidCallback? onComplete}) {
    if (_appOpenShownThisSession) {
      onComplete?.call();
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      onComplete?.call(); // Unavailable: continue immediately.
      return;
    }
    _appOpenShownThisSession = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (d) {
        d.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (d, _) {
        d.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        onComplete?.call();
      },
    );
    ad.show();
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
  void showRewardedAd({
    required void Function(RewardItem reward) onEarnedReward,
    required VoidCallback onComplete,
  }) {
    final show = (RewardedAd ad) {
      _rewardedAd = null;
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

    if (_rewardedAd != null) {
      show(_rewardedAd!);
      return;
    }
    if (_rewardedLoading) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          show(ad);
        },
        onAdFailedToLoad: (_) {
          _rewardedLoading = false;
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
    super.dispose();
  }
}
