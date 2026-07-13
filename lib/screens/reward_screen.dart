import 'dart:async';

import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/constants/app_constants.dart';
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

Future<void> showRewardDialog({
  required BuildContext context,
  required int earnedCoins,
  required int score,
  required int best,
  required DifficultyMode mode,
  required String characterId,
  required int totalFlaps,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return _RewardDialog(
        earnedCoins: earnedCoins,
        score: score,
        best: best,
        mode: mode,
        characterId: characterId,
        totalFlaps: totalFlaps,
      );
    },
  );
}

class _RewardDialog extends StatefulWidget {
  const _RewardDialog({
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
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  bool _processing = false;
  int _adsWatched = 0;
  bool _credited = false;

  Future<bool> _watchOneAd({String? adUnitId}) {
    final completer = Completer<bool>();
    var earned = false;
    sl<AdService>().showRewardedAd(
      adUnitId: adUnitId,
      onEarnedReward: (_) => earned = true,
      onComplete: () => completer.complete(earned),
    );
    return completer.future;
  }

  Future<void> _finish(double multiplier) async {
    if (_credited || !mounted) return;
    _credited = true;
    final gained = (widget.earnedCoins * multiplier).round();
    await sl<CoinService>().addCoins(gained);
    if (multiplier > 1) sl<AudioService>().playSfx(Sfx.rewardReceived);
    if (!mounted) return;
    await replaceWithFade(
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
    final earned = await _watchOneAd(adUnitId: AppConstants.rewardedAdUnitId);
    if (!mounted) return;
    await _finish(earned ? 2 : 1);
  }

  Future<void> _watchThree() async {
    if (_processing) return;
    setState(() => _processing = true);
    var earnedCount = 0;
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      final earned = await _watchOneAd(adUnitId: AppConstants.rewardedAdUnitId2);
      if (earned) earnedCount++;
      setState(() => _adsWatched = i + 1);
    }
    if (!mounted) return;
    await _finish(earnedCount == 3 ? 5 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final earned = widget.earnedCoins;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: NeonPalette.backgroundDark,
          border: Border.all(color: NeonPalette.cyan.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: NeonPalette.cyan.withOpacity(0.25),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              label: '1 AD  ·  2X COINS',
              color: NeonPalette.green,
              enabled: !_processing,
              onPressed: _watchOne,
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: _processing && _adsWatched > 0
                  ? '3 ADS  ·  ${_adsWatched}/3'
                  : '3 ADS  ·  5X COINS',
              color: NeonPalette.cyan,
              enabled: !_processing,
              onPressed: _watchThree,
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'CLOSE  ·  KEEP $earned',
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
    );
  }
}

class RewardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        child: Center(
          child: _RewardDialog(
            earnedCoins: earnedCoins,
            score: score,
            best: best,
            mode: mode,
            characterId: characterId,
            totalFlaps: totalFlaps,
          ),
        ),
      ),
    );
  }
}
