import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/leaderboard_service.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/google_sign_in_screen.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/leaderboard_service.dart';
import 'package:neon_flap1_game/services/vibration_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';
import 'package:neon_flap1_game/store/public_profile_dialog.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

/// Difficulty-specific, all-time rankings. Guest players receive their local
/// personal-best view without ever issuing a Firestore request.
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
  final Map<DifficultyMode, CloudLeaderboardResult> _remote = {};
  bool _loading = true;
  bool _guestMode = false;
  DifficultyMode _activeMode = DifficultyMode.easy;

  T? _service<T extends Object>() {
    try {
      return sl<T>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: DifficultyMode.values.length, vsync: this)
          ..addListener(_onTabChanged);
    _loadActiveMode();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final next = DifficultyMode.values[_tabController.index];
    if (next == _activeMode) return;
    setState(() => _activeMode = next);
    _loadActiveMode();
  }

  Future<void> _loadActiveMode({bool force = false}) async {
    final firebase = _service<FirebaseService>();
    if (firebase == null || firebase.isOfflineGuest) {
      if (mounted) {
        setState(() {
          _guestMode = true;
          _loading = false;
        });
      }
      return;
    }
    if (!force && _remote.containsKey(_activeMode)) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final result = await firebase.leaderboard.top(_activeMode);
    if (mounted) {
      setState(() {
        _guestMode = false;
        _remote[_activeMode] = result;
        _loading = false;
      });
    }
  }

  Future<void> _signIn() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.pushReplacement(fadeRoute(const GoogleSignInScreen()));
  }

  void _openProfile(CloudLeaderboardEntry entry) {
    try {
      sl<AudioService>().playSfx(Sfx.buttonClick);
      sl<VibrationService>().selection();
      showPublicProfileDialog(context, entry.uid);
    } catch (_) {
      // Profile browsing is optional; a missing cloud service must not block
      // the leaderboard row itself.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableListHeight =
        (screenHeight - 248).clamp(150.0, 560.0).toDouble();
    final listHeight =
        (screenHeight * 0.50).clamp(150.0, availableListHeight).toDouble();
    final local = _service<LeaderboardService>();
    final firebase = _service<FirebaseService>();

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
              children: [
                const Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text('LEADERBOARD', style: NeonTextStyle.heading),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.refresh, color: scheme.primary),
                  onPressed: _loading || _guestMode
                      ? null
                      : () => _loadActiveMode(force: true),
                  tooltip: 'Refresh ${_activeMode.name} rankings',
                ),
                SizedBox(
                  width: 78,
                  child: NeonButton(
                    label: 'CLOSE',
                    color: NeonPalette.red,
                    fontSize: 12,
                    height: 44,
                    onPressed: () => Navigator.pop(context),
                  ),
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
                Tab(text: 'EASY'),
                Tab(text: 'NORMAL'),
                Tab(text: 'HARD'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: listHeight,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: DifficultyMode.values
                          .map(
                            (mode) => _LeaderboardList(
                              mode: mode,
                              localEntry: local?.entryFor(mode),
                              guestMode: _guestMode,
                              result: _remote[mode],
                              isMeUid: firebase?.uid,
                              onSignIn: _signIn,
                              onEntryTap: _openProfile,
                              onRetry: () => _loadActiveMode(force: true),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.mode,
    required this.localEntry,
    required this.guestMode,
    required this.result,
    required this.isMeUid,
    required this.onSignIn,
    required this.onEntryTap,
    required this.onRetry,
  });

  final DifficultyMode mode;
  final LeaderboardEntry? localEntry;
  final bool guestMode;
  final CloudLeaderboardResult? result;
  final String? isMeUid;
  final VoidCallback onSignIn;
  final ValueChanged<CloudLeaderboardEntry> onEntryTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (guestMode) {
      return _GuestBoard(
        mode: mode,
        entry: localEntry,
        onSignIn: onSignIn,
      );
    }
    final current = result;
    if (current == null) return const SizedBox.shrink();
    if (current.hasError) {
      return _LoadError(message: current.errorMessage!, onRetry: onRetry);
    }
    final entries = current.entries;
    return Column(
      children: [
        _PersonalBest(mode: mode, entry: localEntry),
        const SizedBox(height: 10),
        Expanded(
          child: entries.isEmpty
              ? const _EmptyBoard()
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final medal = index == 0
                        ? '🥇'
                        : index == 1
                            ? '🥈'
                            : index == 2
                                ? '🥉'
                                : '#${index + 1}';
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onEntryTap(entry),
                      child: _LeaderboardTile(
                        rank: medal,
                        username: entry.username,
                        score: entry.score,
                        bird:
                            CharactersData.byId(entry.selectedCharacterId).name,
                        isMe: entry.uid == isMeUid,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GuestBoard extends StatelessWidget {
  const _GuestBoard({
    required this.mode,
    required this.entry,
    required this.onSignIn,
  });

  final DifficultyMode mode;
  final LeaderboardEntry? entry;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('OFFLINE PERSONAL BEST',
              style: NeonTextStyle.label.copyWith(
                color: NeonPalette.yellow,
              )),
          const SizedBox(height: 10),
          _PersonalBest(mode: mode, entry: entry),
          const SizedBox(height: 18),
          const Text(
            'Sign in with Google to appear in global Easy, Normal, and Hard rankings. '
            'Your offline progress stays on this device.',
            textAlign: TextAlign.center,
            style: NeonTextStyle.body,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            child: NeonButton(
              label: 'SIGN IN',
              icon: Icons.login_rounded,
              color: NeonPalette.cyan,
              onPressed: onSignIn,
            ),
          ),
        ],
      );
}

class _PersonalBest extends StatelessWidget {
  const _PersonalBest({required this.mode, required this.entry});

  final DifficultyMode mode;
  final LeaderboardEntry? entry;

  @override
  Widget build(BuildContext context) {
    final colors = NeonTheme.colors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.field.withValues(alpha: 0.75),
        border: Border.all(color: NeonPalette.yellow.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded, color: NeonPalette.yellow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${mode.name.toUpperCase()} PERSONAL BEST',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NeonTextStyle.label.copyWith(fontSize: 11),
            ),
          ),
          Text(
            '${entry?.score ?? 0} PTS',
            style: NeonTextStyle.body.copyWith(
              color: NeonPalette.yellow,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('NO SCORES YET', style: NeonTextStyle.label),
          SizedBox(height: 8),
          Text(
            'Play this mode to set the first record!',
            style: NeonTextStyle.body,
            textAlign: TextAlign.center,
          ),
        ],
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 34),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center, style: NeonTextStyle.body),
            const SizedBox(height: 14),
            SizedBox(
              width: 132,
              child: NeonButton(
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                height: 44,
                fontSize: 12,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      );
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
    final compact = NeonLayout.isCompact(context);
    final rankWidth = compact ? 34.0 : 42.0;
    final scoreWidth = compact ? 66.0 : 82.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
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
          SizedBox(
            width: rankWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(rank, style: const TextStyle(fontSize: 20)),
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$username (YOU)' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NeonTextStyle.heading.copyWith(fontSize: 16),
                ),
                Text(
                  bird.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NeonTextStyle.label.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          SizedBox(
            width: scoreWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '$score PTS',
                maxLines: 1,
                style: NeonTextStyle.body.copyWith(
                  color: NeonPalette.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
