import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/core/utils/neon_paint.dart';
import 'package:neon_flap_2100/models/character.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/services/owned_characters_service.dart';
import 'package:neon_flap_2100/services/achievement_service.dart';
import 'package:neon_flap_2100/store/characters_data.dart';
import 'package:neon_flap_2100/widgets/animated_background.dart';

/// Premium Character Store: 15 pilots with escalating stats. Tap to unlock
/// (spends coins) or equip (if owned). Always reflects the persisted balance.
class CharacterStoreScreen extends StatelessWidget {
  const CharacterStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final owned = sl<OwnedCharactersService>();
    final coins = sl<CoinService>();
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.purple,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              const Text('CHARACTER STORE', style: NeonTextStyle.heading),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: coins,
                builder: (_, __) => Text(
                  'BALANCE: ${coins.coins} COINS',
                  style: NeonTextStyle.label.copyWith(color: NeonPalette.yellow),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: owned,
                  builder: (_, __) => GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 250,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: CharactersData.roster.length,
                    itemBuilder: (c, i) => _CharacterCard(
                      character: CharactersData.roster[i],
                      owned: owned.isUnlocked(CharactersData.roster[i]),
                      selected: owned.selectedId ==
                          CharactersData.roster[i].id,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NeonBackButton(label: 'BACK', onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.owned,
    required this.selected,
  });

  final Character character;
  final bool owned;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final coins = sl<CoinService>();
    final ownedSvc = sl<OwnedCharactersService>();
    final border = selected
        ? NeonPalette.green
        : owned
            ? character.primary
            : Colors.white24;

    final achievementDef = AchievementDefinition.all
        .where((d) => d.achievement.characterUnlockId == character.id)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: NeonPalette.backgroundDark.withOpacity(0.6),
        border: Border.all(color: border, width: selected ? 3 : 1.5),
        boxShadow: selected
            ? [BoxShadow(color: NeonPalette.green.withOpacity(0.4), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          _CharacterPreview(character: character, size: 54),
          const SizedBox(height: 6),
          Text(character.name.toUpperCase(),
              style: NeonTextStyle.label.copyWith(fontSize: 13)),
          const SizedBox(height: 4),
          _StatMini(stats: character.stats),
          const SizedBox(height: 6),
          if (!owned && achievementDef.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                achievementDef.first.achievement.description,
                style: NeonTextStyle.body.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _ActionButton(
                character: character,
                owned: owned,
                selected: selected,
                onUnlock: () async {
                  final ok = await ownedSvc.unlock(character);
                  if (ok) {
                    sl<AudioService>().playSfx(Sfx.characterUnlock);
                    await ownedSvc.select(character);
                  } else {
                    _toast(context, 'Not enough coins');
                  }
                },
                onSelect: () async {
                  await ownedSvc.select(character);
                  sl<AudioService>().playSfx(Sfx.buttonClick);
                },
                coins: coins.coins,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({required this.character, required this.size});
  final Character character;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            character.primary.withOpacity(0.28),
            Colors.transparent,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _BirdPreviewPainter(
          primary: character.primary,
          accent: character.accent,
        ),
      ),
    );
  }
}

class _BirdPreviewPainter extends CustomPainter {
  _BirdPreviewPainter({required this.primary, required this.accent});
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    drawNeonBird(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width * 0.82,
      primary: primary,
      accent: accent,
      wingPhase: -0.6,
      glow: 9,
    );
  }

  @override
  bool shouldRepaint(covariant _BirdPreviewPainter old) =>
      old.primary != primary || old.accent != accent;
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.stats});
  final CharacterStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('CTRL', stats.control),
      ('JMP', stats.jumpPrecision),
      ('GRV', 2 - stats.gravityScale),
      ('HIT', 2 - stats.hitboxScale),
      ('MAG', stats.coinAttraction),
    ];
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      children: items
          .map((e) => Text(
                '${e.$1} ${(e.$2).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 9,
                  color: NeonPalette.white,
                  letterSpacing: 0.5,
                ),
              ))
          .toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.character,
    required this.owned,
    required this.selected,
    required this.onUnlock,
    required this.onSelect,
    required this.coins,
  });

  final Character character;
  final bool owned;
  final bool selected;
  final VoidCallback onUnlock;
  final VoidCallback onSelect;
  final int coins;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NeonPalette.green),
        ),
        child: const Text('EQUIPPED',
            style: TextStyle(color: NeonPalette.green, fontSize: 12)),
      );
    }
    if (owned) {
      return GestureDetector(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: character.primary.withOpacity(0.18),
            border: Border.all(color: character.primary),
          ),
          child: Text('EQUIP',
              style: TextStyle(color: character.primary, fontSize: 12)),
        ),
      );
    }
    final affordable = coins >= character.price;
    return GestureDetector(
      onTap: affordable ? onUnlock : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: affordable
              ? NeonPalette.yellow.withOpacity(0.15)
              : Colors.white10,
          border: Border.all(
            color: affordable ? NeonPalette.yellow : Colors.white24,
          ),
        ),
        child: Text(
          '${character.price} ◉',
          style: TextStyle(
            color: affordable ? NeonPalette.yellow : Colors.white54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Reusable neon back button.
class NeonBackButton extends StatelessWidget {
  const NeonBackButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        sl<AudioService>().playSfx(Sfx.buttonClick);
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: 200,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonPalette.cyan.withOpacity(0.6)),
          color: NeonPalette.cyan.withOpacity(0.08),
        ),
        child: Text(label,
            style: NeonTextStyle.label),
      ),
    );
  }
}
