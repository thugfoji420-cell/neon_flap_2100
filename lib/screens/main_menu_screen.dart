import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import 'package:neon_flap1_game/widgets/difficulty_selector.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
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
    _readService<AudioService>()?.playMusic(MusicTrack.menu);
    _readService<AdService>()?.loadInterstitialAd();
  }

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
        content: const Text('Close Neon Flap 2100?', style: NeonTextStyle.body),
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

    // Clear only the local authentication / session cache; cloud data is kept.
    final authService = _readService<AuthService>();
    final storageService = _readService<StorageService>();
    if (authService == null) return;
    await authService.signOut(
      clearLocalSession: () async {
        await storageService?.remove('player_name_prompt_completed');
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
          'This will permanently delete your account, username, cloud save, coins, achievements, inventory, settings, leaderboard entries, and all game progress.\n\nThis action cannot be undone.',
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
            title: const Text('Delete Failed', style: NeonTextStyle.heading),
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
            title: const Text('Delete Failed', style: NeonTextStyle.heading),
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
          title: const Text('Delete Failed', style: NeonTextStyle.heading),
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
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: const Text('NEON FLAP', style: NeonTextStyle.title),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          '2100',
                          style: NeonTextStyle.heading.copyWith(
                            color: NeonPalette.cyan,
                            fontSize: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: coinAnimation,
                        builder: (_, __) =>
                            _CoinChip(coins: coinService?.coins ?? 0),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: ownedAnimation,
                        builder: (_, __) => Semantics(
                          label: 'Selected pilot',
                          child: Text(
                            'PILOT: ${(ownedService?.selected.name ?? 'UNKNOWN').toUpperCase()}',
                            style: NeonTextStyle.label,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: firebaseAnimation,
                        builder: (_, __) => Semantics(
                          label: 'Player name',
                          child: Text(
                            'PLAYER NAME: ${(firebaseService?.playerName ?? 'PLAYER').toUpperCase()}',
                            style: NeonTextStyle.label.copyWith(
                              color: NeonPalette.cyan,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      NeonButton(
                        label: 'PLAY',
                        color: NeonPalette.green,
                        onPressed: _play,
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: 'CHARACTER STORE',
                        color: NeonPalette.purple,
                        onPressed: () => pushWithFade(
                          context,
                          const CharacterStoreScreen(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: 'COIN SHOP',
                        color: NeonPalette.yellow,
                        onPressed: () =>
                            pushWithFade(context, const CoinShopScreen()),
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: 'SETTINGS',
                        onPressed: () =>
                            pushWithFade(context, const SettingsScreen()),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label: 'Leaderboard and achievements',
                        child: Row(
                          children: [
                            Expanded(
                              child: NeonButton(
                                label: 'LEADERBOARD',
                                color: NeonPalette.magenta,
                                fontSize: 15,
                                onPressed: () {
                                  _playButtonSfx();
                                  showLeaderboardDialog(context);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NeonButton(
                                label: 'ACHIEVEMENTS',
                                color: NeonPalette.green,
                                fontSize: 15,
                                onPressed: () {
                                  _playButtonSfx();
                                  showAchievementsDialog(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: 'DAILY REWARDS',
                        color: NeonPalette.yellow,
                        fontSize: 15,
                        onPressed: () {
                          _playButtonSfx();
                          showDailyRewardDialog(context);
                        },
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label: 'Account actions',
                        child: Row(
                          children: [
                            Expanded(
                              child: NeonButton(
                                label: 'LOGOUT',
                                color: NeonPalette.red,
                                fontSize: 15,
                                onPressed: _logout,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NeonButton(
                                label: 'DELETE ACCOUNT',
                                color: NeonPalette.red,
                                fontSize: 14,
                                onPressed: _deleteAccount,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: 'EXIT GAME',
                        color: NeonPalette.red,
                        fontSize: 15,
                        onPressed: _exit,
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        label: 'Advertisement banner',
                        child: const BannerAdSlot(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeonPalette.yellow.withOpacity(0.7)),
        color: NeonPalette.yellow.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 12, color: NeonPalette.yellow),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: NeonTextStyle.label.copyWith(
              color: NeonPalette.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
