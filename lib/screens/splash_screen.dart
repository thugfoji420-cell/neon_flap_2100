import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/auth_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/choose_player_name_screen.dart';
import 'package:neon_flap1_game/screens/google_sign_in_screen.dart';
import 'package:neon_flap1_game/screens/main_menu_screen.dart';
import 'package:neon_flap1_game/services/ad_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/coin_sync_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';

/// First screen. Shows the logo, then either restores a persisted Google session
/// and goes straight to the Main Menu, or (when no session exists) plays the
/// (at most one) App Open Ad and transitions to the login screen. Never blocks
/// if the ad is unavailable.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  void _navigate(Widget page) {
    if (_navigated) return;
    _navigated = true;
    if (mounted) replaceWithFade(context, page);
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final authService = sl<AuthService>();
    final firebase = sl<FirebaseService>();

    // Automatic login: a persisted, non-anonymous user exists from a previous
    // Google sign-in. Restore the session and the cloud profile silently and go
    // straight to the Main Menu — the Google chooser must NOT appear.
    if (authService.hasPersistedUser) {
      final restored = await authService.restoreSession();
      if (mounted && restored != null) {
        await _loadProfileAndEnterMainMenu();
        return;
      }
    }

    if (firebase.isOfflineGuest) {
      await firebase.activateOfflineProfile();
      _navigate(const MainMenuScreen());
      return;
    }

    if (firebase.hasActiveIncompleteOfflineProfile) {
      final navigator = Navigator.of(context);
      _navigate(ChoosePlayerNameScreen(
        onComplete: () =>
            navigator.pushReplacement(fadeRoute(const MainMenuScreen())),
      ));
      return;
    }

    // No valid persisted session: show the Login Screen. The App Open Ad may be
    // shown, but the Login Screen is NEVER skipped for logged-out users.
    await _goToLogin();
  }

  /// Plays the (at most one) App Open Ad when available, then shows the Login
  /// Screen. If the ad fails to load/show, the Login Screen is shown anyway so a
  /// logged-out player can never get stuck on the splash.
  Future<void> _goToLogin() async {
    final adService = sl<AdService>();

    final started = DateTime.now();
    while (!adService.isAppOpenAdLoaded &&
        DateTime.now().difference(started).inSeconds < 5) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Show the App Open Ad if available. The Login Screen is shown right after,
    // so a logged-out player can never get stuck on the splash.
    final adShown = await _showLoginAd();
    if (!adShown) {
      // Ad didn't complete in a timely manner; still guarantee the Login Screen.
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _navigate(const GoogleSignInScreen());
  }

  /// Shows the App Open Ad (if loaded) and resolves once it has been dismissed.
  /// Errors are swallowed. Returns true if the ad flow completed.
  Future<bool> _showLoginAd() async {
    try {
      await sl<AdService>().maybeShowAppOpenAd();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads (or creates) the cloud profile for the signed-in user and adopts the
  /// best cloud values into the local services, then enters the Main Menu.
  Future<void> _loadProfileAndEnterMainMenu() async {
    final coins = sl<CoinService>();
    final owned = sl<OwnedCharactersService>();
    final firebase = sl<FirebaseService>();
    final result = await firebase.bootstrap(
      localCoins: coins.coins,
      localHighScore: coins.bestScore,
      avatarId: owned.selectedId,
    );
    await firebase.applyBootstrap(result, coins);
    sl<CoinSyncService>().attach();
    if (firebase.hasPendingGuestMigration) {
      await firebase.mergeOfflineProgress();
    }
    if (!mounted) return;
    _navigate(const MainMenuScreen());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.magenta,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('NEON FLAP', style: NeonTextStyle.title),
              const SizedBox(height: 6),
              Text('2100',
                  style: NeonTextStyle.heading.copyWith(
                    color: scheme.primary,
                    fontSize: 34,
                  )),
              const SizedBox(height: 40),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 18),
              Text('INITIALIZING SYSTEM', style: NeonTextStyle.label),
            ],
          ),
        ),
      ),
    );
  }
}
