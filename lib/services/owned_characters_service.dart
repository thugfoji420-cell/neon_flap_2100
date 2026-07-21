import 'package:flutter/foundation.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/models/character.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

/// Describes the smallest shop-card update needed after an inventory change.
/// A card can ignore changes for other characters instead of rebuilding the
/// entire grid whenever selection or ownership changes.
@immutable
class OwnedCharactersChange {
  const OwnedCharactersChange._({
    required this.revision,
    this.characterId,
    this.previousSelectedId,
    this.affectsAll = false,
  });

  final int revision;
  final String? characterId;
  final String? previousSelectedId;
  final bool affectsAll;

  bool affects(String id) =>
      affectsAll || id == characterId || id == previousSelectedId;
}

/// Tracks which characters are unlocked and which one is selected.
class OwnedCharactersService extends ChangeNotifier {
  OwnedCharactersService(this._storage, this._coins);

  final StorageService _storage;
  final CoinService _coins;

  final Set<String> _unlocked = {};
  final Set<String> _retiredUnlocked = {};
  String _selectedId = CharactersData.roster.first.id;
  final ValueNotifier<OwnedCharactersChange> _changes =
      ValueNotifier(const OwnedCharactersChange._(revision: 0));
  int _changeRevision = 0;

  Set<String> get unlocked => _unlocked;

  /// Includes retired IDs only for cloud/local preservation. The shop and
  /// gameplay use [unlocked], which contains active IDs exclusively.
  Set<String> get allKnownOwnedIds => {
        ..._unlocked,
        ..._retiredUnlocked,
      };
  String get selectedId => _selectedId;
  ValueListenable<OwnedCharactersChange> get changes => _changes;

  Character get selected =>
      CharactersData.roster.firstWhere((c) => c.id == _selectedId,
          orElse: () => CharactersData.roster.first);

  Future<void> load() async {
    final list = _storage.getStringList(StorageKeys.unlockedCharacters);
    final retired =
        _storage.getStringList(StorageKeys.retiredUnlockedCharacters) ??
            const <String>[];
    final knownIds = CharactersData.roster.map((character) => character.id);
    _unlocked.clear();
    _retiredUnlocked
      ..clear()
      ..addAll(retired.where(CharactersData.containsId));
    _unlocked.add(CharactersData.roster.first.id);
    if (list != null) {
      for (final id in list.where(CharactersData.containsId)) {
        if (knownIds.contains(id)) {
          _unlocked.add(id);
        } else {
          _retiredUnlocked.add(id);
          _unlocked.add(CharactersData.mapToActiveId(id));
        }
      }
    }
    final sel = _storage.getString(StorageKeys.selectedCharacter);
    if (sel != null && _unlocked.contains(sel)) {
      _selectedId = sel;
    } else if (sel != null && CharactersData.containsId(sel)) {
      _selectedId = CharactersData.mapToActiveId(sel);
      await _storage.setString(StorageKeys.selectedCharacter, _selectedId);
    }
    // Record that retired inventory IDs have been migrated to the active-ten
    // catalog. Future catalog versions can add an explicit migration step.
    if (_storage.getInt(StorageKeys.characterCatalogVersion) != 2) {
      await _storage.setInt(StorageKeys.characterCatalogVersion, 2);
    }
    _emitChange(affectsAll: true);
    notifyListeners();
  }

  bool isUnlocked(Character c) => c.isFree || _unlocked.contains(c.id);

  /// Unlocks a character, deducting its price from the coin balance.
  /// Returns true on success. Plays the unlock flow via [onUnlocked].
  Future<bool> unlock(Character c) async {
    if (isUnlocked(c)) return true;
    final ok = await _coins.spendCoins(c.price);
    if (!ok) return false;
    _unlocked.add(c.id);
    await _persist();
    _emitChange(characterId: c.id);
    notifyListeners();
    return true;
  }

  Future<void> select(Character c) async {
    if (!isUnlocked(c)) return;
    final previous = _selectedId;
    _selectedId = c.id;
    await _storage.setString(StorageKeys.selectedCharacter, c.id);
    _emitChange(characterId: c.id, previousSelectedId: previous);
    notifyListeners();
  }

  /// Replaces the local inventory with a signed-in user's cloud inventory.
  /// Unknown IDs are ignored, so corrupt or stale cloud rows cannot leave the
  /// shop in an invalid state.
  Future<void> restoreFromCloud({
    required Iterable<String> unlockedIds,
    String? selectedId,
  }) async {
    final knownIds = CharactersData.roster.map((character) => character.id);
    final rawIds = unlockedIds.where(CharactersData.containsId).toSet();
    _unlocked
      ..clear()
      ..add(CharactersData.roster.first.id)
      ..addAll(rawIds.where(knownIds.contains))
      ..addAll(rawIds
          .where((id) => !knownIds.contains(id))
          .map(CharactersData.mapToActiveId));
    _retiredUnlocked
      ..clear()
      ..addAll(rawIds.where((id) => !knownIds.contains(id)));
    _selectedId = selectedId != null && _unlocked.contains(selectedId)
        ? selectedId
        : selectedId != null && CharactersData.containsId(selectedId)
            ? CharactersData.mapToActiveId(selectedId)
            : CharactersData.roster.first.id;
    await _persist();
    _emitChange(affectsAll: true);
    notifyListeners();
  }

  /// Grants the complete roster without spending coins. This is intentionally
  /// separate from [unlock] so purchases retain their normal coin behaviour.
  /// Returns true only when storage changed.
  Future<bool> grantAllCharacters() async {
    final allIds = CharactersData.roster.map((character) => character.id);
    if (allIds.every(_unlocked.contains)) return false;
    _unlocked.addAll(allIds);
    await _persist();
    _emitChange(affectsAll: true);
    notifyListeners();
    return true;
  }

  Future<void> _persist() => _storage
      .setStringList(
        StorageKeys.unlockedCharacters,
        _unlocked.toList()..sort(),
      )
      .then((_) => _storage.setStringList(
            StorageKeys.retiredUnlockedCharacters,
            _retiredUnlocked.toList()..sort(),
          ));

  void reset() {
    _unlocked.clear();
    _retiredUnlocked.clear();
    _unlocked.add(CharactersData.roster.first.id);
    _selectedId = CharactersData.roster.first.id;
    _emitChange(affectsAll: true);
    notifyListeners();
  }

  void _emitChange({
    String? characterId,
    String? previousSelectedId,
    bool affectsAll = false,
  }) {
    _changes.value = OwnedCharactersChange._(
      revision: ++_changeRevision,
      characterId: characterId,
      previousSelectedId: previousSelectedId,
      affectsAll: affectsAll,
    );
  }
}
