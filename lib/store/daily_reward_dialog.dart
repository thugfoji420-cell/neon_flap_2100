import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/daily_reward_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

/// Daily login reward dialog. Shows the current streak, today's reward and
/// lets the player claim it (granting coins) once per calendar day.
Future<void> showDailyRewardDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _DailyRewardDialog(),
  );
}

class _DailyRewardDialog extends StatefulWidget {
  const _DailyRewardDialog();

  @override
  State<_DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<_DailyRewardDialog> {
  DailyRewardStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firebase = sl<FirebaseService>();
    final status = await firebase.dailyRewardStatus();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final firebase = sl<FirebaseService>();
    final gained = await firebase.claimDailyReward();
    if (gained > 0) await sl<CoinService>().addCoins(gained);
    await _load();
    if (mounted) {
      setState(() => _busy = false);
      if (gained > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$gained coins claimed!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: NeonPanel(
        padding: const EdgeInsets.all(24),
        borderColor: NeonPalette.yellow,
        shadowColor: NeonPalette.yellow,
        shadowOpacity: 0.2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DAILY REWARDS', style: NeonTextStyle.heading),
                    const SizedBox(height: 4),
                    Text('PLAYER NAME: ', style: NeonTextStyle.label),
                  ],
                ),
                NeonButton(
                  label: 'CLOSE',
                  color: NeonPalette.red,
                  fontSize: 14,
                  height: 36,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (status == null)
              const Center(
                child: CircularProgressIndicator(color: NeonPalette.yellow),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: NeonTheme.colors(context).field,
                  border:
                      Border.all(color: NeonPalette.yellow.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: NeonPalette.yellow, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAY ${status.day} OF 7',
                            style: NeonTextStyle.label),
                        Text(
                          'Streak: ${status.streak}',
                          style: NeonTextStyle.heading.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${status.rewardCoins}',
                            style: NeonTextStyle.heading.copyWith(
                              color: NeonPalette.yellow,
                            )),
                        const Text('COINS', style: NeonTextStyle.label),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              NeonButton(
                label: status.canClaim
                    ? (_busy ? 'CLAIMING...' : 'CLAIM REWARD')
                    : 'ALREADY CLAIMED TODAY',
                color: NeonPalette.yellow,
                onPressed: status.canClaim && !_busy ? _claim : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
