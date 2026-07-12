import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/routing/route_transitions.dart';
import 'package:neon_flap_2100/screens/main_menu_screen.dart';
import 'package:neon_flap_2100/services/ad_service.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';

/// First screen. Shows the logo, then plays the (at most one) App Open Ad and
/// transitions to the main menu. Never blocks if the ad is unavailable.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    sl<AdService>().maybeShowAppOpenAd(
      onComplete: () {
        if (mounted) replaceWithFade(context, const MainMenuScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.magenta,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('NEON FLAP', style: NeonTextStyle.title),
              const SizedBox(height: 6),
              Text('2100', style: NeonTextStyle.heading.copyWith(
                color: NeonPalette.cyan,
                fontSize: 34,
              )),
              const SizedBox(height: 40),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: NeonPalette.cyan,
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
