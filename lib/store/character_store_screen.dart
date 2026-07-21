import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:neon_flap1_game/characters/character_sprite_catalog.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/models/character.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/achievement_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/banner_ad_slot.dart';
import 'package:neon_flap1_game/widgets/character_avatar.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Premium Character Store: ten active pilots with escalating stats. Tap to unlock
/// (spends coins) or equip (if owned). Always reflects the persisted balance.
class CharacterStoreScreen extends StatefulWidget {
  const CharacterStoreScreen({super.key});

  @override
  State<CharacterStoreScreen> createState() => _CharacterStoreScreenState();
}

class _CharacterStoreScreenState extends State<CharacterStoreScreen> {
  final ValueNotifier<CharacterSpriteFrame> _previewFrame =
      ValueNotifier(CharacterSpriteFrame.idle);
  final ScrollController _scrollController = ScrollController();
  Timer? _previewTimer;
  var _previewIndex = 0;

  @override
  void initState() {
    super.initState();
    _startPreviewTimer();
  }

  // One low-frequency clock drives all built previews. The scroll listener
  // pauses it during motion, so cached/offscreen cards stay static while the
  // grid is being rasterized and no card owns an individual ticker.
  void _startPreviewTimer() {
    if (_previewTimer != null) return;
    _previewTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _previewIndex =
          (_previewIndex + 1) % CharacterSpriteCatalog.previewLoop.length;
      _previewFrame.value = CharacterSpriteCatalog.previewLoop[_previewIndex];
    });
  }

  void _pausePreviewTimer() {
    _previewTimer?.cancel();
    _previewTimer = null;
    _previewFrame.value = CharacterSpriteFrame.idle;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _pausePreviewTimer();
    } else if (notification is ScrollEndNotification) {
      _startPreviewTimer();
    }
    return false;
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _scrollController.dispose();
    _previewFrame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owned = sl<OwnedCharactersService>();
    final coins = sl<CoinService>();
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.purple,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 700
                  ? 4
                  : width >= 500
                      ? 3
                      : 2;
              final horizontalPadding =
                  NeonLayout.isCompact(context) ? 12.0 : 20.0;
              final itemGap = NeonLayout.isCompact(context) ? 10.0 : 14.0;
              final cardWidth =
                  (width - horizontalPadding * 2 - itemGap * (columns - 1)) /
                      columns;
              final cardHeight =
                  (cardWidth * 1.56).clamp(252.0, 288.0).toDouble();

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'CHARACTER STORE',
                            style: NeonTextStyle.heading.copyWith(
                              fontSize: NeonLayout.isCompact(context) ? 22 : 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedBuilder(
                        animation: coins,
                        builder: (_, __) => Semantics(
                          label: 'Coin balance: ${coins.coins}',
                          child: Text(
                            '${coins.coins} COINS AVAILABLE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NeonTextStyle.label.copyWith(
                              color: NeonPalette.yellow,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _onScrollNotification,
                          child: GridView.builder(
                            controller: _scrollController,
                            // A small cache avoids image/layout churn without
                            // keeping an entire 24-card grid alive.
                            cacheExtent: 240,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              12,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisExtent: cardHeight,
                              crossAxisSpacing: itemGap,
                              mainAxisSpacing: itemGap,
                            ),
                            itemCount: CharactersData.roster.length,
                            itemBuilder: (context, index) => _CharacterCard(
                              key: ValueKey(CharactersData.roster[index].id),
                              character: CharactersData.roster[index],
                              ownedService: owned,
                              coinService: coins,
                              previewFrame: _previewFrame,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: NeonBackButton(
                          label: 'BACK',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const BannerAdSlot(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatefulWidget {
  const _CharacterCard({
    super.key,
    required this.character,
    required this.ownedService,
    required this.coinService,
    required this.previewFrame,
  });

  final Character character;
  final OwnedCharactersService ownedService;
  final CoinService coinService;
  final ValueListenable<CharacterSpriteFrame> previewFrame;

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard> {
  bool _busy = false;
  late final AchievementDefinition? _achievementDef;

  @override
  void initState() {
    super.initState();
    final definitions = AchievementDefinition.all
        .where((definition) =>
            definition.achievement.characterUnlockId == widget.character.id)
        .toList(growable: false);
    _achievementDef = definitions.isEmpty ? null : definitions.first;
    widget.ownedService.changes.addListener(_onOwnershipChange);
  }

  @override
  void dispose() {
    widget.ownedService.changes.removeListener(_onOwnershipChange);
    super.dispose();
  }

  void _onOwnershipChange() {
    if (widget.ownedService.changes.value.affects(widget.character.id) &&
        mounted) {
      setState(() {});
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final unlocked = await widget.ownedService.unlock(widget.character);
      if (!mounted) return;
      if (!unlocked) {
        _toast('Not enough coins');
        return;
      }
      sl<AudioService>().playSfx(Sfx.characterUnlock);
      await widget.ownedService.select(widget.character);
    } catch (_) {
      if (mounted) _toast('Unable to unlock this pilot. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.ownedService.select(widget.character);
      sl<AudioService>().playSfx(Sfx.buttonClick);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final owned = widget.ownedService.isUnlocked(widget.character);
    final selected = widget.ownedService.selectedId == widget.character.id;
    final themeColors = NeonTheme.colors(context);
    final border = selected
        ? NeonPalette.green
        : owned
            ? widget.character.primary
            : themeColors.disabled;

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label:
            '${widget.character.name}, ${selected ? 'equipped' : owned ? 'owned' : 'locked'}',
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NeonLayout.panelRadius),
            color: themeColors.panel.withValues(alpha: 0.92),
            border: Border.all(color: border, width: selected ? 2.5 : 1.25),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: NeonPalette.green.withValues(alpha: 0.34),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              CharacterAvatar(
                character: widget.character,
                size: 74,
                selected: selected,
                locked: !owned,
                frameScale: widget.character.shopFrameScale,
                artworkScale: widget.character.shopArtworkScale,
                showBackdrop: false,
                showGlow: false,
                presentation: CharacterAvatarPresentation.fullBird,
                previewFrame: widget.previewFrame,
              ),
              const SizedBox(height: 6),
              Text(
                widget.character.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NeonTextStyle.label.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              _StatMini(stats: widget.character.stats),
              const SizedBox(height: 5),
              if (!owned && _achievementDef != null)
                Text(
                  _achievementDef.achievement.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: NeonTextStyle.body.copyWith(
                    fontSize: 10,
                    color: themeColors.disabled,
                  ),
                )
              else
                Text(
                  owned ? 'READY TO FLY' : widget.character.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: NeonTextStyle.body.copyWith(
                    fontSize: 10,
                    color: selected ? NeonPalette.green : themeColors.disabled,
                  ),
                ),
              const Spacer(),
              _ActionButton(
                character: widget.character,
                owned: owned,
                selected: selected,
                busy: _busy,
                coinService: widget.coinService,
                onUnlock: _unlock,
                onSelect: _select,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        items
            .map((item) => '${item.$1} ${item.$2.toStringAsFixed(2)}')
            .join('  '),
        maxLines: 1,
        style: const TextStyle(fontSize: 9, letterSpacing: 0.35),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.character,
    required this.owned,
    required this.selected,
    required this.busy,
    required this.coinService,
    required this.onUnlock,
    required this.onSelect,
  });

  final Character character;
  final bool owned;
  final bool selected;
  final bool busy;
  final CoinService coinService;
  final VoidCallback onUnlock;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        constraints:
            const BoxConstraints(minHeight: NeonLayout.minimumTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NeonLayout.buttonRadius),
          border: Border.all(color: NeonPalette.green),
          color: NeonPalette.green.withValues(alpha: 0.1),
        ),
        child: const Text(
          'EQUIPPED',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: NeonPalette.green, fontSize: 12),
        ),
      );
    }
    if (owned) {
      return NeonButton(
        label: 'EQUIP',
        icon: Icons.check_circle_outline_rounded,
        color: character.primary,
        fontSize: 12,
        enabled: !busy,
        isLoading: busy,
        onPressed: onSelect,
      );
    }
    // Coin changes rebuild only this compact action, never the bird artwork,
    // card decoration, or the rest of the grid.
    return AnimatedBuilder(
      animation: coinService,
      builder: (_, __) => NeonButton(
        label: 'UNLOCK ${character.price}',
        icon: Icons.monetization_on_outlined,
        color: NeonPalette.yellow,
        fontSize: 11,
        enabled: coinService.coins >= character.price && !busy,
        isLoading: busy,
        onPressed: onUnlock,
      ),
    );
  }
}
