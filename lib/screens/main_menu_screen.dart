import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/auth_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/game_screen.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/services/ad_service.dart';
import 'package:neon_flap1_game/screens/google_sign_in_screen.dart';
import 'package:neon_flap1_game/store/achievements_dialog.dart';
import 'package:neon_flap1_game/store/leaderboard_dialog.dart';
import 'package:neon_flap1_game/settings/settings_screen.dart';
import 'package:neon_flap1_game/store/character_store_screen.dart';
import 'package:neon_flap1_game/store/coin_shop_screen.dart';
import 'package:neon_flap1_game/store/daily_reward_dialog.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/banner_ad_slot.dart';
import 'package:neon_flap1_game/widgets/coin_chip.dart';
import 'package:neon_flap1_game/widgets/difficulty_selector.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Semantic spacing tokens used throughout the main menu layout.
/// Centralised so adjustments propagate consistently across breakpoints.
/// Values are kept tight so the entire menu fits on-screen without scrolling.
class _Spacing {
  const _Spacing._();

  static const double sectionGap = 8;
  static const double itemGap = 8;
  static const double rowGap = 6;
  static const double compactItemGap = 4;
  static const double titleBottom = 10;
  static const double topPadding = 12;
  static const double bottomPadding = 12;
  static const double cardPadding = 8;
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  // Staggered entrance animation: each section fades+slides in sequentially.
  late final AnimationController _entranceCtrl;
  late final List<CurvedAnimation> _sectionAnimations;

  T? _readService<T extends Object>() {
    try {
      return sl<T>();
    } catch (_) {
      return null;
    }
  }

  void _playButtonSfx() {
    _readService<AudioService>()?.playSfx(Sfx.buttonClick);
  }

  @override
  void initState() {
    super.initState();

    // Staggered entrance: 5 sections, 150ms offset per section, 800ms total.
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sectionAnimations = List.generate(5, (i) {
      final start = i * 0.12;
      final end = (start + 0.30).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _entranceCtrl.forward();

    _readService<AudioService>()?.playMusic(MusicTrack.menu);
    _readService<AdService>()?.loadInterstitialAd();
  }

  @override
  void dispose() {
    for (final a in _sectionAnimations) {
      a.dispose();
    }
    _entranceCtrl.dispose();
    super.dispose();
  }

  // --- All business-logic methods preserved verbatim -----------------------

  Future<void> _play() async {
    final mode = await showDifficultySheet(context);
    if (mode == null || !mounted) return;
    await pushWithFade(
      context,
      GameScreen(mode: mode),
    );
  }

  Future<void> _exit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Exit Game?', style: NeonTextStyle.heading),
        content:
            const Text('Close Neon Flap 2100?', style: NeonTextStyle.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL', style: NeonTextStyle.label),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('EXIT', style: NeonTextStyle.label),
          ),
        ],
      ),
    );
    if (ok == true) SystemNavigator.pop();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log Out?', style: NeonTextStyle.heading),
        content: const Text(
            'You will return to the login screen. Your cloud progress stays saved.',
            style: NeonTextStyle.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL', style: NeonTextStyle.label),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('LOG OUT', style: NeonTextStyle.label),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final authService = _readService<AuthService>();
    final storageService = _readService<StorageService>();
    if (authService == null) return;
    await authService.signOut(
      clearLocalSession: () async {
        await storageService?.remove('player_name_prompt_completed');
        // Clear the local coin cache so the next account on this device
        // loads its own cloud balance, not the previous user's cached value.
        await storageService?.remove(StorageKeys.coins);
        await storageService?.remove(StorageKeys.bestScore);
      },
    );
    if (!mounted) return;
    replaceWithFade(context, const GoogleSignInScreen());
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Account', style: NeonTextStyle.heading),
        content: const Text(
          'This will permanently delete your account, username, cloud save, '
          'coins, achievements, inventory, settings, leaderboard entries, and '
          'all game progress.\n\nThis action cannot be undone.',
          style: NeonTextStyle.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL', style: NeonTextStyle.label),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DELETE FOREVER', style: NeonTextStyle.label),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: NeonPalette.cyan),
      ),
    );

    try {
      final firebase = _readService<FirebaseService>();
      if (firebase == null) {
        if (!mounted) return;
        Navigator.pop(context);
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title:
                const Text('Delete Failed', style: NeonTextStyle.heading),
            content: const Text(
              'Account services are unavailable right now.',
              style: NeonTextStyle.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('OK', style: NeonTextStyle.label),
              ),
            ],
          ),
        );
        return;
      }
      final error = await firebase.deleteAccount();
      if (!mounted) return;
      Navigator.pop(context);

      if (error != null) {
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title:
                const Text('Delete Failed', style: NeonTextStyle.heading),
            content: Text(error, style: NeonTextStyle.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('OK', style: NeonTextStyle.label),
              ),
            ],
          ),
        );
        return;
      }

      replaceWithFade(context, const GoogleSignInScreen());
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title:
              const Text('Delete Failed', style: NeonTextStyle.heading),
          content: Text('An unexpected error occurred: $e',
              style: NeonTextStyle.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK', style: NeonTextStyle.label),
            ),
          ],
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Returns a staggered [FadeTransition] + [SlideTransition] wrapper for
  /// the given section index.
  Widget _animateSection(int index, Widget child) {
    final anim = _sectionAnimations[index];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final coinService = _readService<CoinService>();
    final ownedService = _readService<OwnedCharactersService>();
    final firebaseService = _readService<FirebaseService>();
    final coinAnimation = coinService ?? ValueNotifier<int>(0);
    final ownedAnimation = ownedService ?? ValueNotifier<int>(0);
    final firebaseAnimation = firebaseService ?? ValueNotifier<int>(0);

    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.cyan,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isSmall = width < 400;
              final isLarge = width > 600;
              final hp = isSmall ? 16.0 : 28.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: hp,
                  vertical: _Spacing.topPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        _Spacing.topPadding * 2,
                  ),
                  child: Center(
                    child: Container(
                      // On wide screens, constrain the column width so the
                      // layout doesn't stretch horizontally across the full
                      // desktop / tablet viewport.
                      constraints: BoxConstraints(
                        maxWidth: isLarge ? 480 : double.infinity,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _animateSection(
                            0,
                            _buildHeader(
                              coinService,
                              ownedService,
                              firebaseService,
                              coinAnimation,
                              ownedAnimation,
                              firebaseAnimation,
                            ),
                          ),
                          SizedBox(height: _Spacing.sectionGap),
                          _animateSection(
                            1,
                            _buildPlayCard(),
                          ),
                          SizedBox(height: _Spacing.sectionGap),
                          _animateSection(
                            2,
                            _buildStoreCard(isSmall),
                          ),
                          SizedBox(height: _Spacing.sectionGap),
                          _animateSection(
                            3,
                            _buildSocialCard(isSmall),
                          ),
                          SizedBox(height: _Spacing.sectionGap),
                          _animateSection(
                            4,
                            _buildAccountCard(isSmall),
                          ),
                          SizedBox(height: _Spacing.sectionGap),
                          const BannerAdSlot(),
                          const SizedBox(height: _Spacing.bottomPadding),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section builders
  // -------------------------------------------------------------------------

  Widget _buildHeader(
    CoinService? coinService,
    OwnedCharactersService? ownedService,
    FirebaseService? firebaseService,
    Listenable coinAnimation,
    Listenable ownedAnimation,
    Listenable firebaseAnimation,
  ) {
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            'NEON FLAP',
            style: NeonTextStyle.title.copyWith(fontSize: 32),
          ),
        ),
        Semantics(
          header: true,
          child: Text(
            '2100',
            style: NeonTextStyle.heading.copyWith(
              color: NeonPalette.cyan,
              fontSize: 22,
            ),
          ),
        ),
        SizedBox(height: _Spacing.titleBottom),
        AnimatedBuilder(
          animation: coinAnimation,
          builder: (_, __) =>
              CoinChip(coins: coinService?.coins ?? 0),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: ownedAnimation,
          builder: (_, __) => Semantics(
            label: 'Selected pilot',
            child: Text(
              'PILOT: ${(ownedService?.selected.name ?? 'UNKNOWN').toUpperCase()}',
              style: NeonTextStyle.label.copyWith(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 2),
        AnimatedBuilder(
          animation: firebaseAnimation,
          builder: (_, __) => Semantics(
            label: 'Player name',
            child: Text(
              'PLAYER NAME: ${(firebaseService?.playerName ?? 'PLAYER').toUpperCase()}',
              style: NeonTextStyle.label.copyWith(
                fontSize: 12,
                color: NeonPalette.cyan,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Primary action: PLAY with prominent sizing.
  Widget _buildPlayCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeonButton(
              label: 'PLAY',
              color: NeonPalette.green,
              height: 52,
              fontSize: 20,
              onPressed: _play,
            ),
          ],
        ),
      ),
    );
  }

  /// Store section: Character Store + Coin Shop.
  Widget _buildStoreCard(bool isSmall) {
    final gap = isSmall ? _Spacing.compactItemGap : _Spacing.itemGap;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeonButton(
              label: 'CHARACTER STORE',
              color: NeonPalette.purple,
              height: 42,
              fontSize: 16,
              onPressed: () =>
                  pushWithFade(context, const CharacterStoreScreen()),
            ),
            SizedBox(height: gap),
            NeonButton(
              label: 'COIN SHOP',
              color: NeonPalette.yellow,
              height: 42,
              fontSize: 16,
              onPressed: () =>
                  pushWithFade(context, const CoinShopScreen()),
            ),
          ],
        ),
      ),
    );
  }

  /// Social section: Leaderboard, Achievements, Daily Rewards.
  Widget _buildSocialCard(bool isSmall) {
    final gap = isSmall ? _Spacing.compactItemGap : _Spacing.itemGap;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'LEADERBOARD',
                    color: NeonPalette.magenta,
                    fontSize: 14,
                    height: 38,
                    onPressed: () {
                      _playButtonSfx();
                      showLeaderboardDialog(context);
                    },
                  ),
                ),
                SizedBox(width: _Spacing.rowGap),
                Expanded(
                  child: NeonButton(
                    label: 'ACHIEVEMENTS',
                    color: NeonPalette.green,
                    fontSize: 14,
                    height: 38,
                    onPressed: () {
                      _playButtonSfx();
                      showAchievementsDialog(context);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            NeonButton(
              label: 'DAILY REWARDS',
              color: NeonPalette.yellow,
              fontSize: 14,
              height: 38,
              onPressed: () {
                _playButtonSfx();
                showDailyRewardDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Account section: Settings, Logout, Delete Account, Exit.
  Widget _buildAccountCard(bool isSmall) {
    final gap = isSmall ? _Spacing.compactItemGap : _Spacing.itemGap;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeonButton(
              label: 'SETTINGS',
              height: 42,
              fontSize: 16,
              onPressed: () =>
                  pushWithFade(context, const SettingsScreen()),
            ),
            SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'LOGOUT',
                    color: NeonPalette.red,
                    fontSize: 14,
                    height: 36,
                    onPressed: _logout,
                  ),
                ),
                SizedBox(width: _Spacing.rowGap),
                Expanded(
                  child: NeonButton(
                    label: 'DELETE ACCOUNT',
                    color: NeonPalette.red,
                    fontSize: 13,
                    height: 36,
                    onPressed: _deleteAccount,
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            NeonButton(
              label: 'EXIT GAME',
              color: NeonPalette.red,
              fontSize: 14,
              height: 36,
              onPressed: _exit,
            ),
          ],
        ),
      ),
    );
  }
}
