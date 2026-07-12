import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/models/difficulty_config.dart';
import 'package:neon_flap_2100/services/leaderboard_service.dart';
import 'package:neon_flap_2100/store/character_store_screen.dart';
import 'package:neon_flap_2100/store/characters_data.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final leaderboard = sl<LeaderboardService>();
    final entries = leaderboard.entries;
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.magenta,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('LEADERBOARD', style: NeonTextStyle.heading),
                const SizedBox(height: 24),
                if (entries.isEmpty)
                  Column(
                    children: [
                      const Text('NO RUNS YET',
                          style: NeonTextStyle.label),
                      const SizedBox(height: 8),
                      Text(
                        'Play a game to see your scores here.',
                        style: NeonTextStyle.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  ...entries.asMap().entries.map((e) {
                    final index = e.key;
                    final entry = e.value;
                    final medal = index == 0
                        ? '🥇'
                        : index == 1
                            ? '🥈'
                            : index == 2
                                ? '🥉'
                                : '#${index + 1}';
                    return _LeaderboardTile(
                      rank: medal,
                      score: entry.score,
                      difficulty: entry.difficulty,
                      characterId: entry.characterId,
                      date: entry.date,
                    );
                  }),
                const SizedBox(height: 24),
                NeonButton(
                  label: 'RESET',
                  color: NeonPalette.red,
                  onPressed: () async {
                    await leaderboard.reset();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                NeonBackButton(
                  label: 'BACK',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonPalette.cyan.withOpacity(0.35)),
        color: NeonPalette.backgroundDark.withOpacity(0.7),
      ),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$score PTS',
                    style: NeonTextStyle.heading.copyWith(fontSize: 18)),
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
