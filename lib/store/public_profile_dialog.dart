import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/domain/entities/public_player_profile.dart';
import 'package:neon_flap1_game/firebase/public_profile_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

Future<void> showPublicProfileDialog(BuildContext context, String uid) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PublicProfileDialog(uid: uid),
  );
}

class _PublicProfileDialog extends StatefulWidget {
  const _PublicProfileDialog({required this.uid});

  final String uid;

  @override
  State<_PublicProfileDialog> createState() => _PublicProfileDialogState();
}

class _PublicProfileDialogState extends State<_PublicProfileDialog> {
  late final PublicProfileService _service;
  PublicPlayerProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = PublicProfileService(FirebaseFirestore.instance);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final profile = await _service.getProfile(widget.uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
      if (profile == null) _error = 'Profile not found.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final err = _error;
    final profile = _profile;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: Colors.transparent,
      child: NeonPanel(
        maxWidth: 460,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_loading)
              const _LoadingState()
            else if (err != null)
              _ErrorState(message: err, onRetry: _load)
            else if (profile != null)
              _ProfileContent(profile: profile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('PLAYER PROFILE', style: NeonTextStyle.heading),
          NeonButton(
            label: 'CLOSE',
            color: NeonPalette.red,
            fontSize: 12,
            height: 34,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: NeonPalette.red),
          const SizedBox(height: 12),
          Text(message,
              style: NeonTextStyle.body.copyWith(color: NeonPalette.red)),
          const SizedBox(height: 16),
          NeonButton(
              label: 'RETRY', color: NeonPalette.cyan, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final PublicPlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final joinDateStr = _formatDate(profile.joinDate);
    final lastActiveStr = _timeAgo(profile.recentActivity.lastActive);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarHeader(profile: profile),
          const SizedBox(height: 20),
          _SectionTitle('PILOT DATA'),
          const SizedBox(height: 8),
          _InfoRow('PLAYER NAME', profile.username),
          _InfoRow('PLAYER ID', profile.playerId),
          _InfoRow('COUNTRY', profile.country),
          _InfoRow('JOIN DATE', joinDateStr),
          const SizedBox(height: 20),
          _SectionTitle('PERFORMANCE'),
          const SizedBox(height: 8),
          _InfoRow('HIGHEST SCORE', '${profile.highestScore} PTS',
              NeonPalette.yellow),
          _InfoRow('LEVEL', '${profile.level}  ·  ${profile.title}',
              NeonPalette.green),
          _InfoRow('TOTAL GAMES', '${profile.totalGames}', NeonPalette.cyan),
          const SizedBox(height: 20),
          _SectionTitle('CURRENT AIRCRAFT'),
          const SizedBox(height: 8),
          _AircraftRow(profile: profile),
          const SizedBox(height: 20),
          _SectionTitle('ACHIEVEMENTS'),
          const SizedBox(height: 8),
          _AchievementsList(achievements: profile.achievements),
          const SizedBox(height: 20),
          _SectionTitle('RECENT ACTIVITY'),
          const SizedBox(height: 8),
          _ActivityGrid(activity: profile.recentActivity),
          const SizedBox(height: 8),
          Text(
            'LAST ACTIVE: $lastActiveStr',
            style: NeonTextStyle.label.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} DAYS AGO';
    if (diff.inHours > 0) return '${diff.inHours} HOURS AGO';
    if (diff.inMinutes > 0) return '${diff.inMinutes} MINUTES AGO';
    return 'JUST NOW';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.primary.withOpacity(0.4)),
        color: scheme.primary.withOpacity(0.06),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: NeonTextStyle.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, [this.color]);

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeColors = NeonTheme.colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
        color: themeColors.field.withOpacity(0.72),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: NeonTextStyle.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: NeonTextStyle.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.profile});

  final PublicPlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatarColor = profile.currentAvatar.primaryHex == 'nova'
        ? NeonPalette.cyan
        : NeonPalette.magenta;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: avatarColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: avatarColor.withOpacity(0.5),
                blurRadius: 16,
              ),
            ],
          ),
          child: Icon(Icons.flight_rounded, color: avatarColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.username.toUpperCase(),
                style: NeonTextStyle.heading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                profile.title,
                style: TextStyle(
                  fontFamily: NeonTextStyle.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: NeonPalette.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AircraftRow extends StatelessWidget {
  const _AircraftRow({required this.profile});

  final PublicPlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final character = CharactersData.byId(profile.currentAvatar.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: character.primary.withOpacity(0.6)),
        color: character.primary.withOpacity(0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: character.primary.withOpacity(0.2),
              border: Border.all(color: character.primary, width: 2),
            ),
            child:
                Icon(Icons.flight_rounded, color: character.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: NeonTextStyle.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: character.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.currentAvatar.id.toUpperCase(),
                  style: TextStyle(
                    fontFamily: NeonTextStyle.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  const _AchievementsList({required this.achievements});

  final List<PublicAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    final themeColors = NeonTheme.colors(context);
    if (achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          color: themeColors.field.withOpacity(0.72),
        ),
        child: Text(
          'NO ACHIEVEMENTS YET',
          style: NeonTextStyle.label.copyWith(fontSize: 12),
        ),
      );
    }

    final claimed = achievements.where((a) => a.claimed).toList();
    final unclaimed = achievements.where((a) => !a.claimed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (claimed.isNotEmpty) ...[
          Text(
            'CLAIMED (${claimed.length})',
            style: TextStyle(
              fontFamily: NeonTextStyle.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: NeonPalette.green.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: claimed
                .map((a) => _AchievementChip(achievement: a, claimed: true))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (unclaimed.isNotEmpty) ...[
          Text(
            'IN PROGRESS (${unclaimed.length})',
            style: TextStyle(
              fontFamily: NeonTextStyle.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: NeonPalette.yellow.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unclaimed
                .map((a) => _AchievementChip(achievement: a, claimed: false))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({
    required this.achievement,
    required this.claimed,
  });

  final PublicAchievement achievement;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final color = claimed ? NeonPalette.green : NeonPalette.yellow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
        color: color.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(achievement.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontFamily: NeonTextStyle.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: claimed ? NeonPalette.green : NeonPalette.yellow,
            ),
          ),
          if (claimed) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_rounded,
                size: 14, color: NeonPalette.green),
          ],
        ],
      ),
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid({required this.activity});

  final RecentActivity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeColors = NeonTheme.colors(context);
    final items = <_ActivityItem>[
      _ActivityItem(label: 'TOTAL RUNS', value: '${activity.totalRuns}'),
      _ActivityItem(label: 'TOTAL FLAPS', value: '${activity.totalFlaps}'),
      _ActivityItem(label: 'TOTAL SCORE', value: '${activity.totalScoreAll}'),
      _ActivityItem(
        label: 'BEST COINS',
        value: '${activity.maxCoinsSingleRun}',
        color: NeonPalette.yellow,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: items
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                  color: themeColors.field.withOpacity(0.72),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: NeonTextStyle.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: NeonTextStyle.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: item.color ?? scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;
}
