import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/routing/route_transitions.dart';
import 'package:neon_flap_2100/screens/game_screen.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/services/owned_characters_service.dart';
import 'package:neon_flap_2100/services/ad_service.dart';
import 'package:neon_flap_2100/store/achievements_dialog.dart';
import 'package:neon_flap_2100/store/leaderboard_dialog.dart';
import 'package:neon_flap_2100/screens/facebook_dialogs.dart';
import 'package:neon_flap_2100/settings/settings_screen.dart';
import 'package:neon_flap_2100/store/character_store_screen.dart';
import 'package:neon_flap_2100/store/coin_shop_screen.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';
import 'package:neon_flap_2100/widgets/difficulty_selector.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    sl<AudioService>().playMusic(MusicTrack.menu);
    sl<AdService>().loadInterstitialAd();
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
        backgroundColor: NeonPalette.backgroundDark,
        title: const Text('Exit Game?', style: NeonTextStyle.heading),
        content: const Text('Close Neon Flap 2100?',
            style: NeonTextStyle.body),
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

  @override
  Widget build(BuildContext context) {
    final coins = sl<CoinService>();
    final owned = sl<OwnedCharactersService>();
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.cyan,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 36),
                      const Text('NEON FLAP', style: NeonTextStyle.title),
                      Text('2100', style: NeonTextStyle.heading.copyWith(
                        color: NeonPalette.cyan,
                        fontSize: 30,
                      )),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: coins,
                        builder: (_, __) => _CoinChip(coins: coins.coins),
                      ),
                      const SizedBox(height: 6),
                      AnimatedBuilder(
                        animation: owned,
                        builder: (_, __) => Text(
                          'PILOT: ${owned.selected.name.toUpperCase()}',
                          style: NeonTextStyle.label,
                        ),
                      ),
                      const Spacer(),
                      NeonButton(
                          label: 'PLAY',
                          color: NeonPalette.green,
                          onPressed: _play),
                      const SizedBox(height: 12),
                      NeonButton(
                          label: 'CHARACTER STORE',
                          color: NeonPalette.purple,
                          onPressed: () => pushWithFade(
                              context, const CharacterStoreScreen())),
                      const SizedBox(height: 12),
                      NeonButton(
                          label: 'COIN SHOP',
                          color: NeonPalette.yellow,
                          onPressed: () =>
                              pushWithFade(context, const CoinShopScreen())),
                      const SizedBox(height: 12),
                      NeonButton(
                          label: 'SETTINGS',
                          onPressed: () =>
                              pushWithFade(context, const SettingsScreen())),
                      const SizedBox(height: 12),
                      NeonButton(
                        label: 'FACEBOOK LOGIN',
                        color: const Color(0xFF1877F2),
                        fontSize: 15,
                        onPressed: () {
                          sl<AudioService>().playSfx(Sfx.buttonClick);
                          showFacebookLoginDialog(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: NeonButton(
                              label: 'LEADERBOARD',
                              color: NeonPalette.magenta,
                              fontSize: 15,
                              onPressed: () {
                                sl<AudioService>().playSfx(Sfx.buttonClick);
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
                                sl<AudioService>().playSfx(Sfx.buttonClick);
                                showAchievementsDialog(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      NeonButton(
                        label: 'EXIT',
                        color: NeonPalette.red,
                        fontSize: 15,
                        onPressed: _exit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          Text('$coins', style: NeonTextStyle.label.copyWith(
            color: NeonPalette.yellow,
          )),
        ],
      ),
    );
  }
}
