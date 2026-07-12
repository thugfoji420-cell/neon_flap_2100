import 'dart:async';

import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/models/difficulty_config.dart';
import 'package:neon_flap_2100/routing/route_transitions.dart';
import 'package:neon_flap_2100/screens/game_over_screen.dart';
import 'package:neon_flap_2100/screens/run_result.dart';
import 'package:neon_flap_2100/services/ad_service.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

/// Reward screen shown on death. Offers rewarded-ad multipliers (2x / 5x) or
/// a skip. Coins are only credited after [onUserEarnedReward] fires.
class RewardScreen extends StatefulWidget {
  const RewardScreen({
    super.key,
    required this.earnedCoins,
    required this.score,
    required this.best,
    required this.mode,
    required this.characterId,
    required this.totalFlaps,
  });

  final int earnedCoins;
  final int score;
  final int best;
  final DifficultyMode mode;
  final String characterId;
  final int totalFlaps;

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  bool _processing = false;
  int _adsWatched = 0;

  Future<bool> _watchOneAd() {
    final completer = Completer<bool>();
    var earned = false;
    sl<AdService>().showRewardedAd(
      onEarnedReward: (_) => earned = true,
      onComplete: () => completer.complete(earned),
    );
    return completer.future;
  }

  Future<void> _finish(double multiplier) async {
    if (!mounted) return;
    final gained = (widget.earnedCoins * multiplier).round();
    await sl<CoinService>().addCoins(gained);
    if (multiplier > 1) sl<AudioService>().playSfx(Sfx.rewardReceived);
    await pushWithFade(
      context,
      GameOverScreen(
        result: RunResult(
          score: widget.score,
          best: widget.best,
          coinsEarned: gained,
          mode: widget.mode,
          characterId: widget.characterId,
          totalFlaps: widget.totalFlaps,
        ),
      ),
    );
  }

  Future<void> _watchOne() async {
    if (_processing) return;
    setState(() => _processing = true);
    final earned = await _watchOneAd();
    if (!mounted) return;
    await _finish(earned ? 1.5 : 1);
  }

  Future<void> _watchThree() async {
    if (_processing) return;
    setState(() => _processing = true);
    var earnedCount = 0;
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      final earned = await _watchOneAd();
      if (earned) earnedCount++;
      setState(() => _adsWatched = i + 1);
    }
    if (!mounted) return;
    await _finish(earnedCount == 3 ? 2.0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final earned = widget.earnedCoins;
    return Scaffold(
      backgroundColor: NeonPalette.backgroundDeep,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.3,
            colors: [
              NeonPalette.purple.withOpacity(0.18),
              NeonPalette.backgroundDeep,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('GAME OVER', style: NeonTextStyle.title),
                const SizedBox(height: 18),
                Text('YOU EARNED', style: NeonTextStyle.label),
                const SizedBox(height: 6),
                Text('$earned', style: NeonTextStyle.title.copyWith(
                  color: NeonPalette.yellow,
                  fontSize: 56,
                )),
                 Text('COINS', style: NeonTextStyle.label),
                 const SizedBox(height: 28),
                 const Text('CHOOSE REWARD', style: NeonTextStyle.heading),
                 const SizedBox(height: 16),
                NeonButton(
                  label: 'WATCH 1 AD  ·  1.5x COINS',
                  color: NeonPalette.green,
                  enabled: !_processing,
                  onPressed: _watchOne,
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: _processing && _adsWatched > 0
                      ? 'WATCH 3 ADS  ·  ${_adsWatched}/3'
                      : 'WATCH 3 ADS  ·  2x COINS',
                  color: NeonPalette.cyan,
                  enabled: !_processing,
                  onPressed: _watchThree,
                ),
                 const SizedBox(height: 12),
                 NeonButton(
                   label: 'CLOSE  ·  KEEP ${earned}',
                   color: NeonPalette.red,
                   enabled: !_processing,
                   onPressed: () => _finish(1),
                 ),
                 const SizedBox(height: 12),
                 const Text(
                   'Skip = no bonus. Rewards only after the ad is earned.',
                   style: NeonTextStyle.body,
                   textAlign: TextAlign.center,
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
