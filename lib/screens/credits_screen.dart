import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/holo_panel.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Credits / about screen. Shows game info and audio attributions.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  'Developed by Nexora Studios',
                  style: NeonTextStyle.label.copyWith(
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${AppConstants.appVersion}',
                  style: NeonTextStyle.label.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 32),
                const Text('PRODUCTION', style: NeonTextStyle.heading),
                const SizedBox(height: 16),
                const _CreditTile(
                  title: 'Game Design',
                  track: 'Neon Flap 2100',
                  artist: 'Nexora Studios',
                  credit:
                      'Arcade difficulty, character progression, rewards, and cyberpunk game feel.',
                ),
                const SizedBox(height: 12),
                const _CreditTile(
                  title: 'Programming',
                  track: 'Flutter + Flame implementation',
                  artist: 'Nexora Studios',
                  credit:
                      'Gameplay systems, Firebase integration, offline guest mode, UI, storage, ads, and services.',
                ),
                const SizedBox(height: 12),
                const _CreditTile(
                  title: 'UI / UX',
                  track: 'Neon Material 3 interface',
                  artist: 'Nexora Studios',
                  credit:
                      'Embossed glass panels, responsive menus, dialogs, settings, shop, and profile flow.',
                ),
                const SizedBox(height: 12),
                const _CreditTile(
                  title: 'Character and Visual Design',
                  track: 'Futuristic neon bird sprite sheets',
                  artist: 'Nexora Studios',
                  credit:
                      'Detailed transparent bird sprites, city background, pipes, coins, particles, and neon effects.',
                ),
                const SizedBox(height: 32),
                const Text(
                  'BACKGROUND MUSIC',
                  style: NeonTextStyle.heading,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bundled original OGG downloads. Each track is licensed CC0 1.0; '
                  'credits are included voluntarily and work offline.',
                  textAlign: TextAlign.center,
                  style: NeonTextStyle.body,
                ),
                const SizedBox(height: 16),
                for (final track
                    in MusicTrack.byCategory(MusicCategory.menu)) ...[
                  _MusicCreditTile(track: track, category: 'MENU MUSIC'),
                  const SizedBox(height: 12),
                ],
                for (final track
                    in MusicTrack.byCategory(MusicCategory.gameplay)) ...[
                  _MusicCreditTile(track: track, category: 'GAMEPLAY MUSIC'),
                  const SizedBox(height: 12),
                ],
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
                  track: 'ChangeNotifier + AnimatedBuilder',
                  artist: 'Flutter SDK',
                  credit:
                      'https://api.flutter.dev/flutter/widgets/AnimatedBuilder-class.html',
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
                const SizedBox(height: 12),
                const _CreditTile(
                  title: 'Backend Services',
                  track: 'Firebase Authentication + Cloud Firestore',
                  artist: 'Google Firebase',
                  credit:
                      'Google Sign-In, username registration, cloud save, inventory sync, achievements, daily rewards, and leaderboards.',
                ),
                const SizedBox(height: 12),
                const _CreditTile(
                  title: 'Authentication',
                  track: 'Google Sign-In',
                  artist: 'Google',
                  credit: 'Used for account login and cloud synchronization.',
                ),
                const SizedBox(height: 12),
                const _CreditTile(
                  title: 'Special Thanks',
                  track: 'Players and testers',
                  artist: 'Neon Flap 2100 community',
                  credit:
                      'Thanks for flying the neon grid and reporting rough edges.',
                ),
                const SizedBox(height: 12),
                Text(
                  '© 2026 Nexora Studios. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: NeonTextStyle.body.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 32),
                NeonButton(
                  label: 'OPEN SOURCE LICENSES',
                  icon: Icons.article_outlined,
                  color: NeonPalette.cyan,
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                  ),
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'BACK',
                  color: scheme.primary,
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

class _MusicCreditTile extends StatelessWidget {
  const _MusicCreditTile({required this.track, required this.category});

  final MusicTrack track;
  final String category;

  @override
  Widget build(BuildContext context) => _CreditTile(
        title: category,
        track: track.title,
        artist: track.artist,
        credit: '${MusicTrack.licenseName} • Original OGG retained\n'
            'Source: ${track.sourceUrl}\n'
            'Source category: ${track.sourceCategory}\n'
            'Source file: ${track.originalFilename}\n'
            'Bundled: ${track.asset}\n'
            'Downloaded: ${MusicTrack.downloadedOn}\n'
            '${MusicTrack.conversionDetails}',
      );
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: HoloPanel(
        color: scheme.primary,
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}
