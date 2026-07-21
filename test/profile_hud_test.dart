import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/store/characters_data.dart';
import 'package:neon_flap1_game/widgets/character_avatar.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

void main() {
  test('profile values use compact presentation without changing raw values',
      () {
    expect(ProfileStatBox.compactNumber(950), '950');
    expect(ProfileStatBox.compactNumber(1200), '1.2K');
    expect(ProfileStatBox.compactNumber(15000), '15K');
    expect(ProfileStatBox.compactNumber(1100000), '1.1M');
  });

  test('the active catalog remains the approved ten characters', () {
    expect(CharactersData.roster, hasLength(10));
    expect(
      CharactersData.roster.map((character) => character.id),
      orderedEquals(CharactersData.activeIds),
    );
  });

  testWidgets('Gold and High Score stat boxes have equal constraints',
      (tester) async {
    const goldKey = Key('gold-stat');
    const scoreKey = Key('score-stat');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: Column(
              children: const [
                ProfileStatBox(
                  key: goldKey,
                  icon: Icons.monetization_on_rounded,
                  label: 'GOLD',
                  value: 1250000,
                  accent: Color(0xFF8A5700),
                  height: 46,
                ),
                SizedBox(height: 6),
                ProfileStatBox(
                  key: scoreKey,
                  icon: Icons.emoji_events_rounded,
                  label: 'HIGH SCORE',
                  value: 9,
                  accent: Color(0xFF006B78),
                  height: 46,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(goldKey)),
        tester.getSize(find.byKey(scoreKey)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the default avatar preserves the full bird presentation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CharacterAvatar(
            character: CharactersData.roster.first,
            animate: false,
          ),
        ),
      ),
    );

    final avatar = tester.widget<CharacterAvatar>(find.byType(CharacterAvatar));
    expect(avatar.presentation, CharacterAvatarPresentation.fullBird);
    expect(find.byType(ClipOval), findsNothing);
  });
}
