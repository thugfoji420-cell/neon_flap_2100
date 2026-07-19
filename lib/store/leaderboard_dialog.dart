import 'package:flutter/material.dart';

import 'dart:math';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/leaderboard_service.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/vibration_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';
import 'package:neon_flap1_game/store/public_profile_dialog.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

/// Cloud-backed leaderboard with Global / Weekly / Monthly tabs. Falls back to
/// the local leaderboard if Firebase is unavailable.
Future<void> showLeaderboardDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _CloudLeaderboardDialog(),
  );
}

class _CloudLeaderboardDialog extends StatefulWidget {
  const _CloudLeaderboardDialog();

  @override
  State<_CloudLeaderboardDialog> createState() =>
      _CloudLeaderboardDialogState();
}

class _CloudLeaderboardDialogState extends State<_CloudLeaderboardDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<LeaderboardScope, List<CloudLeaderboardEntry>> _cache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final firebase = sl<FirebaseService>();
    for (final scope in LeaderboardScope.values) {
      _cache[scope] = await firebase.leaderboard.top(scope);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                const Text('LEADERBOARD', style: NeonTextStyle.heading),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: scheme.primary),
                      onPressed: _load,
                      tooltip: 'Refresh',
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
              ],
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              indicatorColor: scheme.primary,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'GLOBAL'),
                Tab(text: 'WEEKLY'),
                Tab(text: 'MONTHLY'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: min(360, MediaQuery.of(context).size.height * 0.55),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: LeaderboardScope.values
                          .map((scope) => _LeaderboardList(
                                entries: _cache[scope] ?? const [],
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.entries});

  final List<CloudLeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('NO SCORES YET', style: NeonTextStyle.label),
          SizedBox(height: 8),
          Text(
            'Play a game to climb the ranks!',
            style: NeonTextStyle.body,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return SingleChildScrollView(
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
            child: GestureDetector(
              onTap: () {
                sl<AudioService>().playSfx(Sfx.buttonClick);
                sl<VibrationService>().selection();
                showPublicProfileDialog(context, entry.uid);
              },
              child: _LeaderboardTile(
                rank: medal,
                username: entry.username,
                score: entry.score,
                bird: CharactersData.byId(entry.avatar).name,
                isMe: entry.uid == sl<FirebaseService>().uid,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.username,
    required this.score,
    required this.bird,
    this.isMe = false,
  });

  final String rank;
  final String username;
  final int score;
  final String bird;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final themeColors = NeonTheme.colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? NeonPalette.green.withOpacity(0.9)
              : Theme.of(context).colorScheme.primary.withOpacity(0.35),
        ),
        color: isMe
            ? NeonPalette.green.withOpacity(0.08)
            : themeColors.panel.withOpacity(0.9),
      ),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$username (YOU)' : username,
                  style: NeonTextStyle.heading.copyWith(fontSize: 16),
                ),
                Text(
                  bird.toUpperCase(),
                  style: NeonTextStyle.label.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$score PTS',
            style: NeonTextStyle.body.copyWith(
              color: NeonPalette.yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
