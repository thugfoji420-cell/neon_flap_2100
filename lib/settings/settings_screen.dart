import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/core/theme/theme_controller.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/change_player_name_dialog.dart';
import 'package:neon_flap1_game/legal/legal_document.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/credits_screen.dart';
import 'package:neon_flap1_game/screens/legal_document_screen.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/settings_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/holo_panel.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Settings: volume sliders, vibration, reset progress and legal links.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openLegal(BuildContext context, LegalDocument document) {
    pushWithFade(context, LegalDocumentScreen(document: document));
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
                      const SizedBox(height: 12),
                      _MuteRow(
                        label: 'MUSIC MUTE',
                        muted: s.musicVolume <= 0,
                        onChanged: (muted) =>
                            settings.setMusicVolume(muted ? 0 : 0.6),
                      ),
                      const SizedBox(height: 16),
                      _TrackSelector(
                        label: 'MENU MUSIC',
                        selected: settings.menuTrack,
                        category: MusicCategory.menu,
                        onSelected: settings.setMenuTrack,
                      ),
                      const SizedBox(height: 16),
                      _TrackSelector(
                        label: 'GAMEPLAY MUSIC',
                        selected: settings.gameplayTrack,
                        category: MusicCategory.gameplay,
                        onSelected: settings.setGameplayTrack,
                      ),
                      const SizedBox(height: 16),
                      _SliderRow(
                        label: 'SFX VOLUME',
                        value: s.sfxVolume,
                        onChanged: settings.setSfxVolume,
                      ),
                      const SizedBox(height: 12),
                      _MuteRow(
                        label: 'SFX MUTE',
                        muted: s.sfxVolume <= 0,
                        onChanged: (muted) =>
                            settings.setSfxVolume(muted ? 0 : 0.8),
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
                        icon: Icons.privacy_tip_outlined,
                        onTap: () =>
                            _openLegal(context, LegalDocuments.privacyPolicy),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'TERMS OF SERVICE',
                        icon: Icons.description_outlined,
                        onTap: () =>
                            _openLegal(context, LegalDocuments.termsOfService),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'DATA DELETION INSTRUCTIONS',
                        icon: Icons.delete_outline_rounded,
                        onTap: () =>
                            _openLegal(context, LegalDocuments.dataDeletion),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'CREDITS',
                        icon: Icons.info_outline_rounded,
                        onTap: () =>
                            pushWithFade(context, const CreditsScreen()),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label:
                            'CHANGE NICK NAME: ${sl<FirebaseService>().playerName.toUpperCase()}',
                        icon: Icons.badge_outlined,
                        onTap: () => showChangePlayerNameDialog(context),
                      ),
                      const SizedBox(height: 12),
                      _LinkRow(
                        label: 'RESET PROGRESS',
                        icon: Icons.restart_alt_rounded,
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

class _MuteRow extends StatelessWidget {
  const _MuteRow({
    required this.label,
    required this.muted,
    required this.onChanged,
  });

  final String label;
  final bool muted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: NeonTextStyle.label)),
        SizedBox(
          width: 132,
          child: NeonButton(
            label: muted ? 'UNMUTE' : 'MUTE',
            icon: muted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            height: 42,
            fontSize: 12,
            color: muted ? NeonPalette.green : NeonPalette.purple,
            onPressed: () => onChanged(!muted),
          ),
        ),
      ],
    );
  }
}

class _TrackSelector extends StatelessWidget {
  const _TrackSelector({
    required this.label,
    required this.selected,
    required this.category,
    required this.onSelected,
  });

  final String label;
  final MusicTrack selected;
  final MusicCategory category;
  final Future<void> Function(MusicTrack) onSelected;

  Future<void> _open(BuildContext context) async {
    sl<AudioService>().playSfx(Sfx.buttonClick);
    final audio = sl<AudioService>();
    final trackBeforePreview = audio.currentTrack;
    MusicTrack? previewing;
    final choice = await showModalBottomSheet<MusicTrack>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
          final maxWidth =
              (MediaQuery.sizeOf(context).width - 24).clamp(0.0, 560.0);
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: HoloPanel(
                color: NeonPalette.cyan,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(label, style: NeonTextStyle.heading),
                    const SizedBox(height: 4),
                    Text(
                      'Tap SELECT to choose. Tap PREVIEW to listen.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NeonTextStyle.body.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: maxHeight <= 120
                          ? maxHeight
                          : (maxHeight * 0.38).clamp(96.0, 220.0),
                      child: ListView.separated(
                        itemCount: MusicTrack.byCategory(category).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final track = MusicTrack.byCategory(category)[index];
                          return _TrackOption(
                            track: track,
                            selected: selected == track,
                            previewing: previewing == track,
                            onPreview: () async {
                              await audio.previewMusic(track);
                              if (sheetContext.mounted) {
                                setSheetState(() => previewing = track);
                              }
                            },
                            onSelect: () => Navigator.pop(sheetContext, track),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      label: 'CANCEL',
                      color: NeonPalette.red,
                      height: 44,
                      fontSize: 12,
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (choice == null || choice == selected) {
      await audio.restoreAfterPreview(trackBeforePreview);
      return;
    }
    await onSelected(choice);
    await audio.playMusic(choice);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${choice.title} selected.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NeonTextStyle.label),
        const SizedBox(height: 8),
        NeonButton(
          label: selected.title.toUpperCase(),
          icon: Icons.library_music_outlined,
          color: NeonPalette.cyan,
          height: 48,
          fontSize: 12,
          onPressed: () => _open(context),
        ),
      ],
    );
  }
}

class _TrackOption extends StatelessWidget {
  const _TrackOption({
    required this.track,
    required this.selected,
    required this.previewing,
    required this.onPreview,
    required this.onSelect,
  });

  final MusicTrack track;
  final bool selected;
  final bool previewing;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final narrow = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.12;
    return Semantics(
      label: '${track.title} by ${track.artist}',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (selected ? NeonPalette.green : scheme.primary)
                .withValues(alpha: 0.55),
          ),
          color: NeonTheme.colors(context).field.withValues(alpha: 0.62),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _trackText(onSelect),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _selectButton()),
                        const SizedBox(width: 8),
                        Expanded(child: _previewButton(narrow: true)),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _trackText(onSelect)),
                    const SizedBox(width: 8),
                    _selectButton(),
                    const SizedBox(width: 8),
                    _previewButton(narrow: false),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _trackText(VoidCallback onSelect) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selected)
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: NeonPalette.green),
                  if (selected) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NeonTextStyle.label.copyWith(
                        fontSize: 12,
                        color: selected ? NeonPalette.green : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${track.artist}  •  ${track.sourceCategory}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: NeonTextStyle.body.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      );

  Widget _selectButton() => NeonButton(
        label: 'SELECT',
        icon: Icons.check_rounded,
        color: selected ? NeonPalette.green : NeonPalette.cyan,
        height: 44,
        fontSize: 10,
        onPressed: onSelect,
      );

  Widget _previewButton({required bool narrow}) => SizedBox(
        width: narrow ? double.infinity : 92,
        child: NeonButton(
          label: previewing ? 'PLAYING' : 'PREVIEW',
          icon:
              previewing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
          color: previewing ? NeonPalette.purple : NeonPalette.cyan,
          height: 44,
          fontSize: 10,
          onPressed: onPreview,
        ),
      );
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
    required this.icon,
    required this.onTap,
    this.danger = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return NeonButton(
      label: label,
      icon: icon,
      color: color,
      height: 48,
      fontSize: 12,
      onPressed: onTap,
    );
  }
}
