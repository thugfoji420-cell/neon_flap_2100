import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/game_screen.dart';
import 'package:neon_flap1_game/screens/run_result.dart';
import 'package:neon_flap1_game/services/achievement_service.dart';
import 'package:neon_flap1_game/services/ad_service.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

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
    final firebase = sl<FirebaseService>();
    final storage = sl<StorageService>();
    await achievementService.recordRun(widget.result.score,
        widget.result.coinsEarned, widget.result.totalFlaps);
    await achievementService.evaluateAndClaim(coinService, ownedService);

    final completed = (storage.getInt(StorageKeys.completedGames) ?? 0) + 1;
    await storage.setInt(StorageKeys.completedGames, completed);

    // Push the run result + achievements to the cloud (best-effort, offline-safe).
    final unlocked = <String, bool>{};
    for (final entry in achievementService.progress.entries) {
      unlocked[entry.key] = entry.value.claimed;
    }
    await firebase.onRunComplete(
      score: widget.result.score,
      coinsEarned: widget.result.coinsEarned,
      totalCoins: coinService.coins,
      bestScore: coinService.bestScore,
      mode: widget.result.mode,
      avatarId: ownedService.selectedId,
      achievementsUnlocked: unlocked,
    );
  }

  void _restart() {
    try {
      Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(GameScreen(mode: widget.result.mode)),
        (r) => r.isFirst,
      );
    } catch (e) {
      sl<AudioService>().playSfx(Sfx.buttonClick);
    }
  }

  Future<void> _toMenu() async {
    await sl<AdService>().showInterstitialAd();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final scheme = Theme.of(context).colorScheme;
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
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: sl<FirebaseService>(),
                  builder: (_, __) => Text(
                    'PLAYER: ${sl<FirebaseService>().playerName.toUpperCase()}',
                    style: NeonTextStyle.label.copyWith(color: scheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                _StatRow(
                    label: 'FINAL SCORE',
                    value: '${r.score}',
                    color: scheme.primary),
                const SizedBox(height: 10),
                _StatRow(
                    label: 'BEST SCORE',
                    value: '${r.best}',
                    color: NeonPalette.green),
                const SizedBox(height: 10),
                _StatRow(
                    label: 'COINS EARNED',
                    value: '+${r.coinsEarned}',
                    color: NeonPalette.yellow),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: sl<CoinService>(),
                  builder: (_, __) => _StatRow(
                    label: 'TOTAL COINS',
                    value: '${sl<CoinService>().coins}',
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 28),
                NeonButton(
                    label: 'RESTART',
                    color: NeonPalette.green,
                    onPressed: _restart),
                const SizedBox(height: 12),
                NeonButton(label: 'MAIN MENU', onPressed: _toMenu),
                const SizedBox(height: 12),
                NeonButton(
                    label: 'BACK', color: NeonPalette.red, onPressed: _toMenu),
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
