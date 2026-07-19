import 'package:flutter/foundation.dart';

/// Centralised AdMob configuration. Debug builds automatically use Google's
/// test ad unit ids so no revenue is generated during development.
class AdConstants {
  const AdConstants._();

  static bool get isDebug => kDebugMode;

  // ---------------------------------------------------------------------------
  // Production IDs (user-provided)
  // ---------------------------------------------------------------------------
  static const String productionAppId = 'ca-app-pub-4514520183755342~8331157405';
  static const String productionBanner = 'ca-app-pub-4514520183755342/6809202498';
  static const String productionInterstitial =
      'ca-app-pub-4514520183755342/2631686702';
  static const String productionAppOpen =
      'ca-app-pub-4514520183755342/8159345556';
  static const String productionRewarded2x =
      'ca-app-pub-4514520183755342/7113444507';
  static const String productionRewarded5x =
      'ca-app-pub-4514520183755342/1765749050';

  // ---------------------------------------------------------------------------
  // Google test IDs (official)
  // ---------------------------------------------------------------------------
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const String testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static String get appId =>
      isDebug ? 'ca-app-pub-3940256099942544~3345871719' : productionAppId;

  static String get bannerAdUnitId =>
      isDebug ? testBanner : productionBanner;

  static String get interstitialAdUnitId =>
      isDebug ? testInterstitial : productionInterstitial;

  static String get appOpenAdUnitId =>
      isDebug ? testAppOpen : productionAppOpen;

  static String get rewardedAdUnitId2x =>
      isDebug ? testRewarded : productionRewarded2x;

  static String get rewardedAdUnitId5x =>
      isDebug ? testRewarded : productionRewarded5x;
}
