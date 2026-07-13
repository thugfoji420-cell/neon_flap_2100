import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/services/achievement_service.dart';
import 'package:neon_flap_2100/store/characters_data.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

Future<void> showAchievementsDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return _AchievementsDialog();
    },
  );
}

class _AchievementsDialog extends StatelessWidget {
  const _AchievementsDialog();

  @override
  Widget build(BuildContext context) {
    final achievements = sl<AchievementService>();
    final stats = achievements.stats;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ACHIEVEMENTS', style: NeonTextStyle.heading),
                NeonButton(
                  label: 'CLOSE',
                  color: NeonPalette.red,
                  fontSize: 14,
                  height: 36,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'GAMES PLAYED: ${stats.gamesPlayed}',
              style: NeonTextStyle.label.copyWith(color: NeonPalette.cyan),
            ),
            const SizedBox(height: 4),
            Text(
              'TOTAL FLAPS: ${stats.totalFlaps}  ·  TOTAL SCORE: ${stats.totalScoreAll}',
              style: NeonTextStyle.label.copyWith(color: NeonPalette.cyan),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: AchievementDefinition.all.map((def) {
                    final current = achievements.getProgress(def.statKey);
                    final existing = achievements.progress[def.achievement.id];
                    final claimed = existing?.claimed ?? false;
                    final progress = existing?.progress ?? 0;
                    final pct = def.achievement.target > 0
                        ? (progress / def.achievement.target).clamp(0.0, 1.0)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AchievementTile(
                        achievement: def.achievement,
                        current: current,
                        claimed: claimed,
                        progress: pct,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
        color: (claimed ? NeonPalette.green : NeonPalette.backgroundDark)
            .withOpacity(0.55),
      ),
      child: Row(
        children: [
          Text(achievement.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: NeonTextStyle.heading.copyWith(fontSize: 14)),
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
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  claimed
                      ? 'CLAIMED'
                      : '$current / ${achievement.target}'
                          '${achievement.rewardCoins > 0 ? "  ·  ${achievement.rewardCoins} ◉" : ""}'
                          '${achievement.characterUnlockId != null ? "  ·  Unlock: ${CharactersData.byId(achievement.characterUnlockId!).name}" : ""}',
                  style: NeonTextStyle.label.copyWith(fontSize: 10, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
