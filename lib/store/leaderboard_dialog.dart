import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/models/difficulty_config.dart';
import 'package:neon_flap_2100/services/leaderboard_service.dart';
import 'package:neon_flap_2100/store/characters_data.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

Future<void> showLeaderboardDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return _LeaderboardDialog();
    },
  );
}

class _LeaderboardDialog extends StatefulWidget {
  const _LeaderboardDialog();

  @override
  State<_LeaderboardDialog> createState() => _LeaderboardDialogState();
}

class _LeaderboardDialogState extends State<_LeaderboardDialog> {
  @override
  Widget build(BuildContext context) {
    final leaderboard = sl<LeaderboardService>();
    final entries = leaderboard.entries;
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
                const Text('LEADERBOARD', style: NeonTextStyle.heading),
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
            Flexible(
              child: entries.isEmpty
                  ? Column(
                      children: const [
                        Text('NO RUNS YET', style: NeonTextStyle.label),
                        SizedBox(height: 8),
                        Text(
                          'Play a game to see your scores here.',
                          style: NeonTextStyle.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: entries.asMap().entries.map((e) {
                          final index = e.key;
                          final entry = e.value;
                          final medal = index == 0
                              ? '🥇'
                              : index == 1
                                  ? '🥈'
                                  : index == 2
                                      ? '🥉'
                                      : '#${index + 1}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _LeaderboardTile(
                              rank: medal,
                              score: entry.score,
                              difficulty: entry.difficulty,
                              characterId: entry.characterId,
                              date: entry.date,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'RESET',
              color: NeonPalette.red,
              onPressed: () async {
                await leaderboard.reset();
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.score,
    required this.difficulty,
    required this.characterId,
    required this.date,
  });

  final String rank;
  final int score;
  final DifficultyMode difficulty;
  final String characterId;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final character = CharactersData.byId(characterId);
    final diffLabel = difficulty == DifficultyMode.easy
        ? 'EASY'
        : difficulty == DifficultyMode.normal
            ? 'NORMAL'
            : 'HARD';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonPalette.cyan.withOpacity(0.35)),
        color: NeonPalette.backgroundDark.withOpacity(0.7),
      ),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$score PTS',
                    style: NeonTextStyle.heading.copyWith(fontSize: 16)),
                Text(
                  '${character.name.toUpperCase()}  ·  $diffLabel',
                  style: NeonTextStyle.label.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: NeonTextStyle.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
