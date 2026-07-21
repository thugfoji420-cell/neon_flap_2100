import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// The on-disk contract for every illustrated bird sheet.
///
/// Each source image is a 1536x1024 PNG split into six stable 512x512 cells.
/// The asset mapping deliberately uses the persisted character ID as the file
/// name, so prices, ownership and selected-character storage remain unchanged.
enum CharacterSpriteFrame {
  idle,
  flapUp,
  flapMiddle,
  flapDown,
  glide,
  fall,
}

class CharacterSpriteCatalog {
  const CharacterSpriteCatalog._();

  static const int frameSize = 512;
  static const int columns = 3;
  static const int rows = 2;
  static const int sheetWidth = frameSize * columns;
  static const int sheetHeight = frameSize * rows;

  static const Set<String> characterIds = {
    'nova',
    'pulse',
    'volt',
    'glitch',
    'spectre',
    'quasar',
    'ember',
    'cyber',
    'phantom',
    'aurora',
    'nebula',
    'titan',
    'zenith',
    'singularity',
    'cosmos',
    'eclipse',
    'nova_prime',
    'infinity',
    'omega_plus',
    'myth',
    'legend',
    'apex',
    'genesis',
    'universe',
  };

  static const List<CharacterSpriteFrame> previewLoop = [
    CharacterSpriteFrame.idle,
    CharacterSpriteFrame.flapUp,
    CharacterSpriteFrame.flapMiddle,
    CharacterSpriteFrame.flapDown,
    CharacterSpriteFrame.glide,
  ];

  /// A symmetric sequence that uses the existing illustrated wing poses. The
  /// repeated mid pose removes the sharp down-to-up jump from a three-frame
  /// loop while keeping the original artwork untouched.
  static const List<CharacterSpriteFrame> gameplayFlightLoop = [
    CharacterSpriteFrame.flapUp,
    CharacterSpriteFrame.flapMiddle,
    CharacterSpriteFrame.flapDown,
    CharacterSpriteFrame.flapMiddle,
  ];

  static String assetFor(String characterId) {
    final resolvedId =
        characterIds.contains(characterId) ? characterId : 'nova';
    return 'assets/characters/$resolvedId.png';
  }

  static ui.Rect sourceRect(CharacterSpriteFrame frame) {
    final index = frame.index;
    final column = index % columns;
    final row = index ~/ columns;
    return ui.Rect.fromLTWH(
      column * frameSize.toDouble(),
      row * frameSize.toDouble(),
      frameSize.toDouble(),
      frameSize.toDouble(),
    );
  }

  static CharacterSpriteFrame previewFrameForProgress(double progress) {
    final index = (progress * previewLoop.length).floor() % previewLoop.length;
    return previewLoop[index];
  }

  /// Resolves a stable gameplay wing pose from normalized elapsed time.
  static CharacterSpriteFrame gameplayFrameForProgress(double progress) {
    if (!progress.isFinite) return CharacterSpriteFrame.flapMiddle;
    final normalized = progress - progress.floorToDouble();
    final index = (normalized * gameplayFlightLoop.length)
        .floor()
        .clamp(0, gameplayFlightLoop.length - 1);
    return gameplayFlightLoop[index];
  }
}

/// Shared decoded-image cache used by Flame, the main-menu portrait and the
/// character shop. This prevents separate widgets from decoding a 1536x1024
/// sheet repeatedly.
class CharacterSpriteCache {
  CharacterSpriteCache._();

  static final Map<String, Future<ui.Image>> _pending = {};

  static Future<ui.Image> load(String characterId) {
    final asset = CharacterSpriteCatalog.assetFor(characterId);
    return _pending.putIfAbsent(asset, () => _decode(asset));
  }

  static Future<void> preload(String characterId) async {
    await load(characterId);
  }

  static Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }
}
