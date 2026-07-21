import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/services/achievement_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

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
    AchievementService? achievements;
    try {
      achievements = sl<AchievementService>();
    } catch (_) {
      // Keep the dialog renderable if a transient startup failure leaves the
      // service unavailable.
    }
    final stats = achievements?.stats ?? const PlayerStats();
    final progressById =
        achievements?.progress ?? const <String, AchievementProgress>{};
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: NeonPanel(
        maxWidth: 520,
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
              style: NeonTextStyle.label
                  .copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'TOTAL FLAPS: ${stats.totalFlaps}  ·  TOTAL SCORE: ${stats.totalScoreAll}',
              style: NeonTextStyle.label
                  .copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            // ConstrainedBox avoids Expanded which can trigger multi-pass
            // layout in Dialog overlays (causing child.hasSize assertions).
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: AchievementDefinition.all.map((def) {
                    final current = achievements?.getProgress(def.statKey) ?? 0;
                    final existing = progressById[def.achievement.id];
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
    final themeColors = NeonTheme.colors(context);
    final color =
        claimed ? NeonPalette.green : Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
        color: (claimed
                ? Theme.of(context).colorScheme.primaryContainer
                : themeColors.panel)
            .withOpacity(claimed ? 0.55 : 0.55),
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
                    backgroundColor: themeColors.field,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  claimed
                      ? 'CLAIMED'
                      : _achievementSubtitle(achievement, current),
                  style:
                      NeonTextStyle.label.copyWith(fontSize: 10, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _achievementSubtitle(Achievement a, int current) {
    final unlockId = a.characterUnlockId;
    return '$current / ${a.target}'
        '${a.rewardCoins > 0 ? "  ·  ${a.rewardCoins} ◉" : ""}'
        '${unlockId != null ? "  ·  Unlock: ${CharactersData.byId(unlockId).name}" : ""}';
  }
}
