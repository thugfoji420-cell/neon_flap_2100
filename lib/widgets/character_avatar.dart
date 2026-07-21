import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:neon_flap1_game/characters/character_sprite_catalog.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/models/character.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

/// Preserves the full original bird frame for all avatar presentations.
enum CharacterAvatarPresentation { portrait, fullBird }

/// Cached raster bird artwork shared by the profile and store.
///
/// No procedural geometry is used here: every frame comes from the matching
/// transparent character sheet in [CharacterSpriteCatalog]. Store cards can
/// share a low-frequency clock through [previewAnimation], avoiding one ticker
/// per card.
class CharacterAvatar extends StatefulWidget {
  const CharacterAvatar({
    super.key,
    required this.character,
    this.size = 72,
    this.selected = false,
    this.locked = false,
    this.presentation = CharacterAvatarPresentation.fullBird,
    this.frame,
    this.previewFrame,
    this.previewAnimation,
    this.animate = true,
    this.frameScale = 0.82,
    this.artworkScale = 0.96,
    this.showBackdrop = true,
    this.showGlow = true,
    this.glowBehindArtwork = false,
  });

  final Character character;
  final double size;
  final bool selected;
  final bool locked;
  final CharacterAvatarPresentation presentation;
  final CharacterSpriteFrame? frame;
  final ValueListenable<CharacterSpriteFrame>? previewFrame;
  final Animation<double>? previewAnimation;
  final bool animate;

  /// Decorative frame and full-artwork scale inside the reserved avatar zone.
  /// The frame never clips the artwork; bird details may extend beyond it.
  final double frameScale;
  final double artworkScale;

  /// Store cards can remove the filled frame so transparent sprite pixels do
  /// not inherit a dark circular shade from the avatar presentation.
  final bool showBackdrop;

  /// Store cards can rely on their crisp ring border without a broad halo.
  final bool showGlow;

  /// Keeps decorative glow behind the raster artwork when a crisp preview is
  /// more important than the glassy profile treatment.
  final bool glowBehindArtwork;

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  Object? _loadError;
  AnimationController? _localPreviewController;

  bool get _usesLocalAnimation =>
      widget.animate &&
      widget.frame == null &&
      widget.previewFrame == null &&
      widget.previewAnimation == null;

  @override
  void initState() {
    super.initState();
    _loadCharacterSheet();
    if (_usesLocalAnimation) {
      _localPreviewController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CharacterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _image = null;
      _loadError = null;
      _loadCharacterSheet();
    }
  }

  Future<void> _loadCharacterSheet() async {
    try {
      final image = await CharacterSpriteCache.load(widget.character.id);
      if (mounted) setState(() => _image = image);
    } catch (error) {
      debugPrint(
          'Unable to load character sprite ${widget.character.id}: $error');
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  void dispose() {
    _localPreviewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline =
        widget.selected ? widget.character.accent : widget.character.primary;
    final safeSize = widget.size.clamp(40.0, 176.0).toDouble();
    final frameSize = safeSize * widget.frameScale.clamp(0.48, 1.0).toDouble();
    final artworkSize =
        safeSize * widget.artworkScale.clamp(0.72, 1.20).toDouble();
    final themeColors = NeonTheme.colors(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      image: true,
      label: '${widget.character.name} character',
      child: RepaintBoundary(
        child: SizedBox(
          width: safeSize,
          height: safeSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.showBackdrop
                      ? themeColors.hudSurface.withValues(
                          alpha: isLight ? 0.94 : 0.74,
                        )
                      : null,
                  border: Border.all(
                    color:
                        outline.withValues(alpha: widget.locked ? 0.38 : 0.9),
                    width: widget.selected ? 2.5 : 1.5,
                  ),
                ),
              ),
              if (widget.showGlow && widget.glowBehindArtwork)
                _buildGlow(outline, frameSize),
              _buildArtwork(artworkSize),
              if (widget.showGlow && !widget.glowBehindArtwork)
                _buildGlow(outline, frameSize),
              if (widget.locked)
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NeonPalette.backgroundDeep.withValues(alpha: 0.54),
                  ),
                  child: const SizedBox.expand(
                    child: Center(
                      child: Icon(Icons.lock_rounded, size: 22),
                    ),
                  ),
                ),
              if (widget.selected)
                const Positioned(
                  right: 1,
                  bottom: 1,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: NeonPalette.green,
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: NeonPalette.backgroundDeep,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlow(Color outline, double frameSize) {
    final tier = CharactersData.tierFor(widget.character.id);
    final tierGlow = switch (tier) {
      CharacterTier.standard => 0.30,
      CharacterTier.premium => 0.38,
      CharacterTier.elite => 0.46,
      CharacterTier.legendary => 0.56,
    };
    final tierBlur = switch (tier) {
      CharacterTier.standard => 10.0,
      CharacterTier.premium => 13.0,
      CharacterTier.elite => 16.0,
      CharacterTier.legendary => 20.0,
    };
    return IgnorePointer(
      child: Container(
        width: frameSize * 0.96,
        height: frameSize * 0.96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: outline.withValues(
                alpha: widget.locked ? 0.08 : tierGlow,
              ),
              blurRadius: tierBlur * 1.6,
              spreadRadius: tierBlur * 0.35,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(double artworkSize) {
    final image = _image;
    if (image == null) {
      return SizedBox.expand(
        child: Center(
          child: Icon(
            _loadError == null
                ? Icons.downloading_rounded
                : Icons.broken_image_outlined,
            color: widget.character.primary.withValues(alpha: 0.7),
            size: 22,
          ),
        ),
      );
    }

    if (widget.frame case final fixedFrame?) {
      return _paintFrame(image, fixedFrame, artworkSize);
    }
    if (widget.previewFrame case final sharedFrame?) {
      return ValueListenableBuilder<CharacterSpriteFrame>(
        valueListenable: sharedFrame,
        builder: (_, frame, __) => _paintFrame(image, frame, artworkSize),
      );
    }
    if (widget.previewAnimation case final sharedAnimation?) {
      return AnimatedBuilder(
        animation: sharedAnimation,
        builder: (_, __) => _paintFrame(
          image,
          CharacterSpriteCatalog.previewFrameForProgress(sharedAnimation.value),
          artworkSize,
        ),
      );
    }
    final localController = _localPreviewController;
    if (localController == null) {
      return _paintFrame(image, CharacterSpriteFrame.idle, artworkSize);
    }
    return AnimatedBuilder(
      animation: localController,
      builder: (_, __) => _paintFrame(
        image,
        CharacterSpriteCatalog.previewFrameForProgress(localController.value),
        artworkSize,
      ),
    );
  }

  Widget _paintFrame(
    ui.Image image,
    CharacterSpriteFrame frame,
    double artworkSize,
  ) {
    return SizedBox(
      width: artworkSize,
      height: artworkSize,
      child: CustomPaint(
        painter: _CharacterSpritePainter(
          image: image,
          frame: frame,
          presentation: widget.presentation,
        ),
      ),
    );
  }
}

class _CharacterSpritePainter extends CustomPainter {
  const _CharacterSpritePainter({
    required this.image,
    required this.frame,
    required this.presentation,
  });

  final ui.Image image;
  final CharacterSpriteFrame frame;
  final CharacterAvatarPresentation presentation;

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = CharacterSpriteCatalog.sourceRect(frame);
    // Every presentation uses the full 512px animation cell. The cells are
    // square, as is the destination, so this is the canvas equivalent of
    // BoxFit.contain with the original aspect ratio preserved.
    final source = switch (presentation) {
      CharacterAvatarPresentation.fullBird => frameRect,
      CharacterAvatarPresentation.portrait => frameRect,
    };
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterSpritePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.frame != frame ||
      oldDelegate.presentation != presentation;
}
