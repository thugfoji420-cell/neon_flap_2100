import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

import '../helpers/mock_services.dart';

void main() {
  late FakeStorageService storage;
  late CoinService coins;
  late OwnedCharactersService owned;

  setUp(() async {
    storage = FakeStorageService();
    coins = CoinService(storage);
    owned = OwnedCharactersService(storage, coins);
    await owned.load();
  });

  test('shop exposes exactly ten active characters', () {
    expect(CharactersData.roster, hasLength(10));
    expect(CharactersData.activeIds, hasLength(10));
    expect(CharactersData.roster.map((c) => c.id),
        orderedEquals(CharactersData.activeIds));
  });

  test('active shop prices include the 400-credit adjustment', () {
    expect(
      {
        for (final character in CharactersData.roster)
          character.id: character.price,
      },
      const {
        'nova': 0,
        'pulse': 1200,
        'volt': 1400,
        'glitch': 1700,
        'spectre': 2100,
        'quasar': 2600,
        'ember': 3200,
        'titan': 9400,
        'genesis': 160400,
        'universe': 220400,
      },
    );
  });

  test('all-character grant unlocks and persists every roster entry', () async {
    final changed = await owned.grantAllCharacters();

    expect(changed, isTrue);
    expect(owned.unlocked, containsAll(CharactersData.roster.map((c) => c.id)));
    expect(
      storage.getStringList(StorageKeys.unlockedCharacters),
      containsAll(CharactersData.roster.map((c) => c.id)),
    );

    final restored = OwnedCharactersService(storage, coins);
    await restored.load();
    expect(
      restored.unlocked,
      containsAll(CharactersData.roster.map((c) => c.id)),
    );
    expect(await restored.grantAllCharacters(), isFalse);
  });

  test('cloud inventory ignores unknown birds and repairs selected bird',
      () async {
    await owned.restoreFromCloud(
      unlockedIds: const ['pulse', 'not-a-real-bird'],
      selectedId: 'not-a-real-bird',
    );

    expect(owned.unlocked, containsAll(const ['nova', 'pulse']));
    expect(owned.unlocked, isNot(contains('not-a-real-bird')));
    expect(owned.selectedId, 'nova');
  });

  test('retired ownership is preserved while selection maps to active bird',
      () async {
    await owned.restoreFromCloud(
      unlockedIds: const ['cyber', 'pulse'],
      selectedId: 'cyber',
    );

    expect(owned.unlocked, containsAll(const ['nova', 'pulse', 'quasar']));
    expect(owned.selectedId, 'quasar');
    expect(owned.allKnownOwnedIds, contains('cyber'));
    expect(
      storage.getStringList(StorageKeys.retiredUnlockedCharacters),
      contains('cyber'),
    );
  });

  test('all-character entitlement matches only the requested Google account',
      () {
    expect(
      AccountEntitlements.unlocksAllCharacters('r.mubashar.rm@gmail.com'),
      isTrue,
    );
    expect(
      AccountEntitlements.unlocksAllCharacters('R.MUBASHAR.RM@GMAIL.COM'),
      isTrue,
    );
    expect(
      AccountEntitlements.unlocksAllCharacters('another.player@gmail.com'),
      isFalse,
    );
    expect(AccountEntitlements.unlocksAllCharacters(null), isFalse);
  });
}
