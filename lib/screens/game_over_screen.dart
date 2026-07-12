import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/routing/route_transitions.dart';
import 'package:neon_flap_2100/screens/game_screen.dart';
import 'package:neon_flap_2100/screens/run_result.dart';
import 'package:neon_flap_2100/services/achievement_service.dart';
import 'package:neon_flap_2100/services/ad_service.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/services/owned_characters_service.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

/// End-of-run summary. Presents score, best, coins earned and the running
/// balance, with Restart / Main Menu / Back actions.
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key, required this.result});

  final RunResult result;

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  @override
  void initState() {
    super.initState();
    sl<AudioService>().playMusic(MusicTrack.menu);
    _evaluateAchievements();
  }

  Future<void> _evaluateAchievements() async {
    final achievementService = sl<AchievementService>();
    final coinService = sl<CoinService>();
    final ownedService = sl<OwnedCharactersService>();
    await achievementService.recordRun(widget.result.score, widget.result.coinsEarned, widget.result.totalFlaps);
    await achievementService.evaluateAndClaim(coinService, ownedService);
  }

  void _restart() {
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(GameScreen(mode: widget.result.mode)),
      (r) => r.isFirst,
    );
  }

  Future<void> _toMenu() async {
    await sl<AdService>().showInterstitialAd();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.red,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('RUN COMPLETE', style: NeonTextStyle.heading),
                const SizedBox(height: 24),
                _StatRow(label: 'FINAL SCORE', value: '${r.score}',
                    color: NeonPalette.cyan),
                const SizedBox(height: 10),
                _StatRow(label: 'BEST SCORE', value: '${r.best}',
                    color: NeonPalette.green),
                const SizedBox(height: 10),
                _StatRow(label: 'COINS EARNED', value: '+${r.coinsEarned}',
                    color: NeonPalette.yellow),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: sl<CoinService>(),
                  builder: (_, __) => _StatRow(
                    label: 'TOTAL COINS',
                    value: '${sl<CoinService>().coins}',
                    color: NeonPalette.white,
                  ),
                ),
                const SizedBox(height: 28),
                NeonButton(label: 'RESTART', color: NeonPalette.green,
                    onPressed: _restart),
                const SizedBox(height: 12),
                NeonButton(label: 'MAIN MENU', onPressed: _toMenu),
                const SizedBox(height: 12),
                NeonButton(label: 'BACK', color: NeonPalette.red,
                    onPressed: _toMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
        color: color.withOpacity(0.06),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: NeonTextStyle.label),
          Text(value, style: NeonTextStyle.heading.copyWith(color: color)),
        ],
      ),
    );
  }
}
