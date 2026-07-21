import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/characters/character_sprite_catalog.dart';
import 'package:neon_flap1_game/core/constants/game_constants.dart';
import 'package:neon_flap1_game/game/components/player.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every persisted character ID has a decodable six-frame sprite sheet',
      () async {
    final rosterIds =
        CharactersData.roster.map((character) => character.id).toSet();
    // Retired sheets remain in the catalog for safe migration, while only
    // the active ten are exposed by the shop.
    expect(CharacterSpriteCatalog.characterIds, containsAll(rosterIds));

    for (final characterId in rosterIds) {
      final data =
          await rootBundle.load(CharacterSpriteCatalog.assetFor(characterId));
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, CharacterSpriteCatalog.sheetWidth);
      expect(frame.image.height, CharacterSpriteCatalog.sheetHeight);
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('each animation state maps to a stable 512px cell', () {
    for (final frame in CharacterSpriteFrame.values) {
      final source = CharacterSpriteCatalog.sourceRect(frame);
      expect(source.width, CharacterSpriteCatalog.frameSize.toDouble());
      expect(source.height, CharacterSpriteCatalog.frameSize.toDouble());
      expect(source.left, inInclusiveRange(0, 1024));
      expect(source.top, inInclusiveRange(0, 512));
    }
  });

  test('gameplay flight cycle uses a smooth return through the middle pose',
      () {
    expect(CharacterSpriteCatalog.gameplayFlightLoop, const [
      CharacterSpriteFrame.flapUp,
      CharacterSpriteFrame.flapMiddle,
      CharacterSpriteFrame.flapDown,
      CharacterSpriteFrame.flapMiddle,
    ]);

    expect(
      CharacterSpriteCatalog.gameplayFrameForProgress(0),
      CharacterSpriteFrame.flapUp,
    );
    expect(
      CharacterSpriteCatalog.gameplayFrameForProgress(0.25),
      CharacterSpriteFrame.flapMiddle,
    );
    expect(
      CharacterSpriteCatalog.gameplayFrameForProgress(0.5),
      CharacterSpriteFrame.flapDown,
    );
    expect(
      CharacterSpriteCatalog.gameplayFrameForProgress(0.75),
      CharacterSpriteFrame.flapMiddle,
    );
    expect(
      CharacterSpriteCatalog.gameplayFrameForProgress(1),
      CharacterSpriteFrame.flapUp,
    );
  });

  test('active characters use bounded visual-only gameplay metadata', () {
    for (final character in CharactersData.roster) {
      final visual = character.gameplayVisual;
      expect(visual.scale, inInclusiveRange(0.9, 1.3));
      expect(visual.flapCycleDuration, greaterThan(0));
      expect(visual.glowOpacity, inInclusiveRange(0, 1));
      expect(visual.innerGlowOpacity, inInclusiveRange(0, 1));
      expect(visual.tapGlowBoost, inInclusiveRange(0, 1));
      expect(
        CharacterSpriteCatalog.assetFor(character.id),
        isNotEmpty,
      );
    }
  });

  test('unknown character IDs fall back to the starter gameplay sheet', () {
    expect(
      CharacterSpriteCatalog.assetFor('missing-character'),
      CharacterSpriteCatalog.assetFor('nova'),
    );
  });

  test('visual scale and glow do not alter the collision radius', () {
    for (final character in CharactersData.roster) {
      final player = Player(character: character);
      expect(
        player.hitboxRadius,
        closeTo(
          GameConstants.playerSize * 0.30 * character.stats.hitboxScale,
          0.0001,
        ),
      );
    }
  });
}
