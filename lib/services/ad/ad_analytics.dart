import 'package:flutter/foundation.dart';

/// Types of ad events for analytics and debugging.
enum AdEventType {
  bannerLoaded,
  bannerFailed,
  bannerClicked,
  bannerClosed,
  interstitialLoaded,
  interstitialFailed,
  interstitialShown,
  interstitialClicked,
  interstitialDismissed,
  appOpenLoaded,
  appOpenShown,
  appOpenDismissed,
  appOpenFailed,
  rewardedLoaded,
  rewardedFailed,
  rewardedShown,
  rewardEarned,
  rewardGranted,
  adInit,
}

/// Lightweight ad analytics logger. Replace with Firebase Analytics or similar
/// in production; this keeps the core logic testable and decoupled.
class AdAnalytics {
  AdAnalytics({this.onEvent});

  final void Function(AdEventType type, Map<String, dynamic> data)? onEvent;

  void log(AdEventType type, [Map<String, dynamic> data = const {}]) {
    if (kDebugMode) {
      debugPrint('[AdAnalytics] $type ${data.isNotEmpty ? data : ''}');
    }
    onEvent?.call(type, data);
  }
}
