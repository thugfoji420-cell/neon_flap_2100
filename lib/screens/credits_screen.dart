import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

/// Credits / about screen. Shows game info and audio attributions.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.magenta,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('CREDITS', style: NeonTextStyle.heading),
                const SizedBox(height: 24),
                Text(
                  'NEON FLAP 2100',
                  style: NeonTextStyle.title.copyWith(fontSize: 28),
                ),
                Text(
                  'v1.0.0',
                  style: NeonTextStyle.label.copyWith(
                    color: NeonPalette.cyan,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'BACKGROUND MUSIC',
                  style: NeonTextStyle.heading,
                ),
                const SizedBox(height: 16),
                _CreditTile(
                  title: 'Menu BGM',
                  track: 'Better Times are Coming',
                  artist: 'Alejandro Magaña (A. M.)',
                  credit:
                      'Better Times are Coming by Alejandro Magaña (A. M.)\n'
                      'Licensed under Mixkit Free License\n'
                      'https://mixkit.co/free-stock-music/mood/futuristic/',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'Gameplay BGM',
                  track: 'Infected Vibes',
                  artist: 'Alejandro Magaña (A. M.)',
                  credit:
                      'Infected Vibes by Alejandro Magaña (A. M.)\n'
                      'Licensed under Mixkit Free License\n'
                      'https://mixkit.co/free-stock-music/mood/energetic/',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'Sound Effects',
                  track: 'Synthesized SFX',
                  artist: 'Neon Flap 2100',
                  credit:
                      'All sound effects were synthesized programmatically\n'
                      'using custom DSP generators.',
                ),
                const SizedBox(height: 32),
                const Text(
                  'BUILT WITH',
                  style: NeonTextStyle.heading,
                ),
                const SizedBox(height: 16),
                _CreditTile(
                  title: 'Framework',
                  track: 'Flutter',
                  artist: 'Google',
                  credit: 'https://flutter.dev',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'Game Engine',
                  track: 'Flame',
                  artist: 'Flame Team',
                  credit: 'https://flame-engine.org',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'Audio',
                  track: 'audioplayers',
                  artist: 'bluefireteam',
                  credit: 'https://pub.dev/packages/audioplayers',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'Dependency Injection',
                  track: 'get_it',
                  artist: 'fluttercommunity.dev',
                  credit: 'https://pub.dev/packages/get_it',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'State Management',
                  track: 'Provider',
                  artist: 'fluttercommunity.dev',
                  credit: 'https://pub.dev/packages/provider',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'Storage',
                  track: 'shared_preferences',
                  artist: 'fluttercommunity.dev',
                  credit: 'https://pub.dev/packages/shared_preferences',
                ),
                const SizedBox(height: 12),
                _CreditTile(
                  title: 'Ads & Purchases',
                  track: 'google_mobile_ads + in_app_purchase',
                  artist: 'Google',
                  credit: 'https://pub.dev/packages/google_mobile_ads\n'
                      'https://pub.dev/packages/in_app_purchase',
                ),
                const Spacer(),
                NeonButton(
                  label: 'BACK',
                  color: NeonPalette.cyan,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  const _CreditTile({
    required this.title,
    required this.track,
    required this.artist,
    required this.credit,
  });

  final String title;
  final String track;
  final String artist;
  final String credit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeonPalette.cyan.withOpacity(0.4)),
        color: NeonPalette.backgroundDark.withOpacity(0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NeonTextStyle.label.copyWith(fontSize: 12)),
          const SizedBox(height: 6),
          Text(track, style: NeonTextStyle.heading.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text(artist, style: NeonTextStyle.label.copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            credit,
            style: NeonTextStyle.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
