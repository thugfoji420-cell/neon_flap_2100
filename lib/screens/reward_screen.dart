import 'dart:async';

import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/game_over_screen.dart';
import 'package:neon_flap1_game/screens/run_result.dart';
import 'package:neon_flap1_game/services/ad_service.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

import 'package:neon_flap1_game/services/ad/ad_constants.dart';

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
  String? _sessionKey;

  @override
  void initState() {
    super.initState();
    _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _finish(double multiplier) async {
    if (_credited || !mounted) return;
    _credited = true;

    // Base coins were already credited in _die(). Here we only add the bonus
    // portion: 0x for skip, +1x for 2x ad, +4x for 5x ad.
    final bonus = (widget.earnedCoins * (multiplier - 1)).round();
    if (bonus > 0) {
      final sessionKey = _sessionKey ?? 'default';
      final rewardKey = '$sessionKey-$multiplier';
      if (!sl<AdService>().wasRewarded(rewardKey)) {
        // Credit the coins FIRST so they survive a Firestore failure.
        await sl<CoinService>().addCoins(bonus);
        sl<AudioService>().playSfx(Sfx.rewardReceived);
        await sl<AdService>().markRewarded(rewardKey);
        // Best-effort Firestore audit — failure must not block the reward.
        await sl<AdService>().grantReward(
          coinAmount: bonus,
          rewardType: multiplier == 2 ? 'rewarded_2x' : 'rewarded_5x',
          adUnitId: multiplier == 2
              ? AdConstants.productionRewarded2x
              : AdConstants.productionRewarded5x,
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(fadeRoute(
      GameOverScreen(
        result: RunResult(
          score: widget.score,
          best: widget.best,
          // Total earned this run = base (credited in _die) + bonus.
          coinsEarned: widget.earnedCoins + bonus,
          mode: widget.mode,
          characterId: widget.characterId,
          totalFlaps: widget.totalFlaps,
        ),
      ),
    ));
  }

  Future<void> _watchOne() async {
    if (_processing) return;
    setState(() => _processing = true);

    final completer = Completer<bool>();
    var earned = false;
    sl<AdService>().showRewardedAd(
      adUnitId: AdConstants.rewardedAdUnitId2x,
      onEarnedReward: (_) => earned = true,
      onComplete: () => completer.complete(earned),
    );

    final result = await completer.future;
    if (!mounted) return;
    await _finish(result ? 2 : 1);
  }

  Future<void> _watchThree() async {
    if (_processing) return;
    setState(() => _processing = true);
    var earnedCount = 0;
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      final completer = Completer<bool>();
      var earned = false;
      sl<AdService>().showRewardedAd(
        adUnitId: AdConstants.rewardedAdUnitId5x,
        onEarnedReward: (_) => earned = true,
        onComplete: () => completer.complete(earned),
      );
      final result = await completer.future;
      if (result) earnedCount++;
      setState(() => _adsWatched = i + 1);
    }
    if (!mounted) return;
    await _finish(earnedCount == 3 ? 5 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final earned = widget.earnedCoins;
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: NeonPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME OVER', style: NeonTextStyle.title),
            const SizedBox(height: 18),
            Text('YOU EARNED', style: NeonTextStyle.label),
            const SizedBox(height: 6),
            Text('$earned',
                style: NeonTextStyle.title.copyWith(
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
              color: scheme.primary,
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
