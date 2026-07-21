import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:neon_flap1_game/characters/character_sprite_catalog.dart';
import 'package:neon_flap1_game/store/characters_data.dart';
import 'package:neon_flap1_game/widgets/character_avatar.dart';

/// Development-only contact sheet for art review.
///
/// This widget is intentionally not registered in release navigation. It gives
/// developers one screen to compare every character at large, shop and gameplay
/// sizes while checking their chosen frame for alignment and readability.
class CharacterSpriteReview extends StatelessWidget {
  const CharacterSpriteReview({
    super.key,
    this.frame = CharacterSpriteFrame.idle,
  });

  final CharacterSpriteFrame frame;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Character sprite review')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          mainAxisExtent: 286,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: CharactersData.roster.length,
        itemBuilder: (context, index) {
          final character = CharactersData.roster[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(character.name, maxLines: 1),
                  const SizedBox(height: 8),
                  CharacterAvatar(
                    character: character,
                    size: 148,
                    frame: frame,
                    animate: false,
                    presentation: CharacterAvatarPresentation.fullBird,
                  ),
                  const SizedBox(height: 8),
                  const Text('Shop / gameplay / avatar'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CharacterAvatar(
                        character: character,
                        size: 72,
                        frame: frame,
                        animate: false,
                        presentation: CharacterAvatarPresentation.fullBird,
                      ),
                      CharacterAvatar(
                        character: character,
                        size: 44,
                        frame: frame,
                        animate: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
