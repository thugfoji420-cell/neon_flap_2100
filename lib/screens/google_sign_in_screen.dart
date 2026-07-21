import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/auth_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/choose_player_name_screen.dart';
import 'package:neon_flap1_game/screens/main_menu_screen.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/coin_sync_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/offline_profile_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Intermediate screen shown after the splash/ad flow.
///
/// Offers Google cloud sign-in and an explicit local guest mode for account-free
/// offline play.
class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _loading = false;
  String? _loadingMessage;

  void _setLoading(bool value, {String? message}) {
    if (!mounted) return;
    setState(() {
      _loading = value;
      _loadingMessage = message;
    });
  }

  Future<void> _continueWithGoogle() async {
    if (_loading) return;
    _setLoading(true, message: 'Opening Google Sign-In...');
    try {
      final authService = sl<AuthService>();
      final user = await authService.signInWithGoogle();

      if (!mounted) return;

      // No user (cancelled / failed): show an error if we have one, otherwise
      // stay on the login screen.
      if (user == null) {
        final err = authService.error;
        if (err != null && mounted) {
          await _showErrorDialog('Sign-in failed', err);
        }
        _setLoading(false);
        return;
      }

      final firebase = sl<FirebaseService>();
      final hadOfflineProgress = firebase.hasPendingGuestMigration ||
          firebase.hasCompletedOfflineProfile;
      if (hadOfflineProgress) {
        _setLoading(true, message: 'Saving offline progress...');
        await firebase.prepareForOnlineSignIn();
      }

      // Load (or create) this Google account's isolated cloud profile.
      _setLoading(true, message: 'Loading cloud profile...');
      final coins = sl<CoinService>();
      final owned = sl<OwnedCharactersService>();
      final result = await firebase.bootstrap(
        localCoins: coins.coins,
        localHighScore: coins.bestScore,
        avatarId: owned.selectedId,
      );
      if (!mounted) return;
      await firebase.applyBootstrap(result, coins);
      // Logout detaches sync before account-local values are cleared. Reattach
      // only after this account's cloud values have been adopted.
      sl<CoinSyncService>().attach();

      // Brand-new Google accounts (no existing players/{uid} document) must
      // create a username before entering the game. Returning users — whose
      // profile already existed — skip straight to the main menu.
      if (firebase.needsPlayerName) {
        if (!mounted) return;
        if (kDebugMode) debugPrint('Navigating to ChoosePlayerNameScreen');
        final navigator = Navigator.of(context);
        await navigator.pushReplacement(
          fadeRoute(ChoosePlayerNameScreen(
            onComplete: () async {
              if (kDebugMode) {
                debugPrint(
                    'ChoosePlayerNameScreen.onComplete: navigating to MainMenu');
              }
              await _syncOfflineProgressIfNeeded(
                firebase: firebase,
                hadOfflineProgress: hadOfflineProgress,
                showMessage: false,
              );
              navigator.pushReplacement(fadeRoute(const MainMenuScreen()));
            },
          )),
        );
        if (kDebugMode) debugPrint('Returned from ChoosePlayerNameScreen');
        return;
      }

      await _syncOfflineProgressIfNeeded(
        firebase: firebase,
        hadOfflineProgress: hadOfflineProgress,
      );
      if (!mounted) return;
      replaceWithFade(context, const MainMenuScreen());
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        await _showErrorDialog(
          'Authentication failed',
          e.message ?? 'Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        await _showErrorDialog(
          'Something went wrong',
          'We could not sign you in. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  Future<void> _playOffline() async {
    if (_loading) return;
    _setLoading(true, message: 'Creating offline profile...');
    try {
      final firebase = sl<FirebaseService>();
      final result = await firebase.activateOfflineProfile();
      if (!mounted) return;
      if (result == OfflineProfileStart.ready) {
        replaceWithFade(context, const MainMenuScreen());
        return;
      }

      final navigator = Navigator.of(context);
      await navigator.pushReplacement(
        fadeRoute(ChoosePlayerNameScreen(
          onComplete: () =>
              navigator.pushReplacement(fadeRoute(const MainMenuScreen())),
        )),
      );
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<bool> _syncOfflineProgressIfNeeded({
    required FirebaseService firebase,
    required bool hadOfflineProgress,
    bool showMessage = true,
  }) async {
    if (!hadOfflineProgress) return true;
    _setLoading(true, message: 'Syncing offline progress...');
    final synced = await firebase.mergeOfflineProgress();
    if (!mounted || !showMessage) return synced;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Offline progress synced successfully.'
              : 'Google sign-in succeeded, but offline progress is still syncing safely.',
        ),
      ),
    );
    return synced;
  }

  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: NeonTextStyle.heading),
        content: Text(message, style: NeonTextStyle.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK', style: NeonTextStyle.label),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.magenta,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('NEON FLAP', style: NeonTextStyle.title),
                Text('2100',
                    style: NeonTextStyle.heading.copyWith(
                      color: scheme.primary,
                      fontSize: 34,
                    )),
                const SizedBox(height: 50),
                NeonButton(
                  label: 'CONTINUE WITH GOOGLE',
                  color: scheme.primary,
                  icon: Icons.login_rounded,
                  fontSize: 16,
                  onPressed: _loading ? null : _continueWithGoogle,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  label: 'PLAY OFFLINE',
                  color: NeonPalette.purple,
                  icon: Icons.sports_esports_rounded,
                  fontSize: 16,
                  onPressed: _loading ? null : _playOffline,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Play without an account. Progress stays on this device.',
                    textAlign: TextAlign.center,
                    style: NeonTextStyle.body.copyWith(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (_loadingMessage ?? 'Connecting...').toUpperCase(),
                        textAlign: TextAlign.center,
                        style: NeonTextStyle.label.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                NeonButton(
                  label: 'EXIT GAME',
                  color: NeonPalette.red,
                  fontSize: 16,
                  onPressed: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
