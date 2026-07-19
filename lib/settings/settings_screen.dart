import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/core/theme/theme_controller.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/change_player_name_dialog.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/credits_screen.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/settings_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/store/character_store_screen.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';

/// Settings: volume sliders, vibration, reset progress and legal links.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset Progress?', style: NeonTextStyle.heading),
        content: const Text(
            'This erases coins, best score and all unlocked characters.',
            style: NeonTextStyle.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('CANCEL', style: NeonTextStyle.label)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('RESET', style: NeonTextStyle.label)),
        ],
      ),
    );
    if (ok != true) return;
    final storage = sl<StorageService>();
    await sl<SettingsService>().resetProgress(storage);
    await sl<CoinService>().load();
    await sl<OwnedCharactersService>().load();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Progress reset')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsService>();
    final themeController = sl<ThemeController>();
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.cyan,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            // Scrollable so the settings list never overflows short screens.
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: Listenable.merge([settings, themeController]),
                builder: (_, __) {
                  final s = settings.settings;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SETTINGS', style: NeonTextStyle.heading),
                      const SizedBox(height: 24),
                      _SliderRow(
                        label: 'MUSIC VOLUME',
                        value: s.musicVolume,
                        onChanged: settings.setMusicVolume,
                      ),
                      const SizedBox(height: 16),
                      _SliderRow(
                        label: 'SFX VOLUME',
                        value: s.sfxVolume,
                        onChanged: settings.setSfxVolume,
                      ),
                      const SizedBox(height: 16),
                      _ToggleRow(
                        label: 'VIBRATION',
                        value: s.vibration,
                        onChanged: settings.setVibration,
                      ),
                      const SizedBox(height: 24),
                      _ThemeModeRow(
                        value: themeController.themeMode,
                        onChanged: themeController.setThemeMode,
                      ),
                      const SizedBox(height: 24),
                      _LinkRow(
                        label: 'PRIVACY POLICY',
                        onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'TERMS OF SERVICE',
                        onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'DATA DELETION INSTRUCTIONS',
                        onTap: () => _openUrl(AppConstants.dataDeletionUrl),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'CREDITS',
                        onTap: () =>
                            pushWithFade(context, const CreditsScreen()),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label:
                            'PLAYER NAME: ${sl<FirebaseService>().playerName.toUpperCase()}',
                        onTap: () => showChangePlayerNameDialog(context),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'RESET PROGRESS',
                        danger: true,
                        onTap: () => _reset(context),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: NeonBackButton(
                          label: 'BACK',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NeonTextStyle.label),
        Slider(
          value: value,
          onChanged: (v) => onChanged(v),
          onChangeEnd: (_) => sl<AudioService>().playSfx(Sfx.buttonClick),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: NeonTextStyle.label),
        Switch(
          value: value,
          onChanged: (v) {
            sl<AudioService>().playSfx(Sfx.buttonClick);
            onChanged(v);
          },
        ),
      ],
    );
  }
}

/// Material 3 appearance selector. System is the default and tracks device
/// changes automatically; explicit modes are saved by [ThemeController].
class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({required this.value, required this.onChanged});

  final ThemeMode value;
  final Future<void> Function(ThemeMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('APPEARANCE', style: NeonTextStyle.label),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('SYSTEM'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('LIGHT'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('DARK'),
              ),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              sl<AudioService>().playSfx(Sfx.buttonClick);
              onChanged(selection.first);
            },
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        sl<AudioService>().playSfx(Sfx.buttonClick);
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.6)),
          color: color.withOpacity(0.06),
        ),
        child: Text(label, style: NeonTextStyle.label.copyWith(color: color)),
      ),
    );
  }
}
