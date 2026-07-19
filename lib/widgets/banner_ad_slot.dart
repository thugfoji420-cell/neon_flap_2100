import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:neon_flap1_game/services/ad/ad_constants.dart';

class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _bannerAd;
  int _retryCount = 0;
  Timer? _retryTimer;
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _retryCount = 0;
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) debugPrint('BannerAdSlot: load failed: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          _scheduleRetry();
        },
      ),
    )..load();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetries) {
      if (kDebugMode) debugPrint('BannerAdSlot: max retries reached');
      return;
    }
    final delay = _baseRetryDelay * pow(2, _retryCount).toInt();
    _retryCount++;
    if (kDebugMode) {
      debugPrint('BannerAdSlot: retry $_retryCount in $delay');
    }
    _retryTimer = Timer(delay, _loadBanner);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      height: 50,
      child: AdWidget(ad: ad),
    );
  }
}
