import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/services/achievement_service.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/store/characters_data.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = sl<AchievementService>();
    final stats = achievements.stats;
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.green,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        sl<AudioService>().playSfx(Sfx.buttonClick);
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: NeonPalette.cyan.withOpacity(0.6)),
                          color: NeonPalette.cyan.withOpacity(0.08),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: NeonPalette.cyan, size: 18),
                            const SizedBox(width: 8),
                            const Text('BACK', style: NeonTextStyle.label),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Text('ACHIEVEMENTS', style: NeonTextStyle.heading),
                 const SizedBox(height: 8),
                 Text(
                   'GAMES PLAYED: ${stats.gamesPlayed}',
                   style: NeonTextStyle.label.copyWith(color: NeonPalette.cyan),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   'TOTAL FLAPS: ${stats.totalFlaps}  ·  TOTAL SCORE: ${stats.totalScoreAll}',
                   style: NeonTextStyle.label.copyWith(color: NeonPalette.cyan),
                 ),
                const SizedBox(height: 24),
                ...AchievementDefinition.all.map((def) {
                  final current = achievements.getProgress(def.statKey);
                  final existing = achievements.progress[def.achievement.id];
                  final claimed = existing?.claimed ?? false;
                  final progress = existing?.progress ?? 0;
                  final pct = def.achievement.target > 0
                      ? (progress / def.achievement.target).clamp(0.0, 1.0)
                      : 0.0;
                  return _AchievementTile(
                    achievement: def.achievement,
                    current: current,
                    claimed: claimed,
                    progress: pct,
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.current,
    required this.claimed,
    required this.progress,
  });

  final Achievement achievement;
  final int current;
  final bool claimed;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final color = claimed ? NeonPalette.green : NeonPalette.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
        color: (claimed ? NeonPalette.green : NeonPalette.backgroundDark)
            .withOpacity(0.55),
      ),
      child: Row(
        children: [
          Text(achievement.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: NeonTextStyle.heading.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(achievement.description,
                    style: NeonTextStyle.body.copyWith(fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: NeonPalette.backgroundDeep,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  claimed
                      ? 'CLAIMED'
                      : '$current / ${achievement.target}'
                          '${achievement.rewardCoins > 0 ? "  ·  ${achievement.rewardCoins} ◉" : ""}'
                          '${achievement.characterUnlockId != null ? "  ·  Unlock: ${CharactersData.byId(achievement.characterUnlockId!).name}" : ""}',
                  style: NeonTextStyle.label.copyWith(fontSize: 11, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
