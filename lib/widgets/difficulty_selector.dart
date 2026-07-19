import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Presents the three difficulty modes and resolves with the chosen one.
/// Shown when the player taps Play on the main menu.
Future<DifficultyMode?> showDifficultySheet(BuildContext context) {
  return showModalBottomSheet<DifficultyMode>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _DifficultySheet(),
  );
}

class _DifficultySheet extends StatelessWidget {
  const _DifficultySheet();

  @override
  Widget build(BuildContext context) {
    final colors = NeonTheme.colors(context);
    final scheme = Theme.of(context).colorScheme;
    final modes = [
      (
        DifficultyMode.easy,
        'Largest gaps · slowest speed · no obstacles',
        NeonPalette.green,
      ),
      (
        DifficultyMode.normal,
        'Smaller gaps · moving obstacles · faster',
        NeonPalette.cyan,
      ),
      (
        DifficultyMode.hard,
        'Smallest gaps · fast hazards · brutal',
        NeonPalette.red,
      ),
    ];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.panel,
        border: Border.all(color: scheme.primary.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SELECT DIFFICULTY', style: NeonTextStyle.heading),
          const SizedBox(height: 16),
          for (final m in modes) ...[
            _ModeRow(mode: m.$1, desc: m.$2, color: m.$3),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.mode,
    required this.desc,
    required this.color,
  });

  final DifficultyMode mode;
  final String desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cfg = DifficultyConfig.preset(mode);
    return NeonButton(
      label: '${mode.name.toUpperCase()}  ·  +${cfg.coinPerScore} coins/score',
      color: color,
      height: 64,
      onPressed: () {
        sl<AudioService>().playSfx(Sfx.buttonClick);
        Navigator.of(context).pop(mode);
      },
    );
  }
}
