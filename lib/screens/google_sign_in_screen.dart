import 'package:flutter/material.dart';
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
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Intermediate screen shown after the splash/ad flow.
///
/// Offers a single entry point: "Continue with Google". If the user cancels
/// the Google picker, the app still proceeds with the existing anonymous
/// session so the game remains playable offline.
class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _loading = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);
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
        if (mounted) setState(() => _loading = false);
        return;
      }

      final firebase = sl<FirebaseService>();

      // Load (or create) this Google account's isolated cloud profile.
      final coins = sl<CoinService>();
      final owned = sl<OwnedCharactersService>();
      final result = await firebase.bootstrap(
        localCoins: coins.coins,
        localHighScore: coins.bestScore,
        avatarId: owned.selectedId,
      );
      if (!mounted) return;
      await firebase.applyBootstrap(result, coins);

      // Brand-new Google accounts (no existing players/{uid} document) must
      // create a username before entering the game. Returning users — whose
      // profile already existed — skip straight to the main menu.
      if (firebase.needsPlayerName) {
        if (!mounted) return;
        if (kDebugMode) debugPrint('Navigating to ChoosePlayerNameScreen');
        final navigator = Navigator.of(context);
        await navigator.pushReplacement(
          fadeRoute(ChoosePlayerNameScreen(
            onComplete: () {
              if (kDebugMode) {
                debugPrint(
                    'ChoosePlayerNameScreen.onComplete: navigating to MainMenu');
              }
              navigator.pushReplacement(fadeRoute(const MainMenuScreen()));
            },
          )),
        );
        if (kDebugMode) debugPrint('Returned from ChoosePlayerNameScreen');
        return;
      }

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
        setState(() => _loading = false);
      }
    }
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
                  fontSize: 16,
                  onPressed: _loading ? null : _continueWithGoogle,
                ),
                if (_loading) ...[
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
