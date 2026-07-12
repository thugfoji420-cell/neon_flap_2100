import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:neon_flap_2100/core/constants/app_constants.dart';
import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/routing/route_transitions.dart';
import 'package:neon_flap_2100/screens/credits_screen.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/services/owned_characters_service.dart';
import 'package:neon_flap_2100/services/settings_service.dart';
import 'package:neon_flap_2100/services/storage_service.dart';
import 'package:neon_flap_2100/store/character_store_screen.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';

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
        backgroundColor: NeonPalette.backgroundDark,
        title: const Text('Reset Progress?', style: NeonTextStyle.heading),
        content: const Text(
            'This erases coins, best score and all unlocked characters.',
            style: NeonTextStyle.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
              child: const Text('CANCEL', style: NeonTextStyle.label)),
          TextButton(onPressed: () => Navigator.pop(c, true),
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
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.cyan,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: settings,
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
                      label: 'CREDITS',
                      onTap: () => pushWithFade(context, const CreditsScreen()),
                    ),
                    const SizedBox(height: 12),
                    _LinkRow(
                      label: 'RESET PROGRESS',
                      danger: true,
                      onTap: () => _reset(context),
                    ),
                    const Spacer(),
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
          activeColor: NeonPalette.cyan,
          inactiveColor: NeonPalette.cyan.withOpacity(0.2),
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
          activeColor: NeonPalette.green,
          onChanged: (v) {
            sl<AudioService>().playSfx(Sfx.buttonClick);
            onChanged(v);
          },
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
    final color = danger ? NeonPalette.red : NeonPalette.cyan;
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
