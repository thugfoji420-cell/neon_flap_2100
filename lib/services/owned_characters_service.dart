import 'package:flutter/foundation.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/models/character.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

/// Tracks which characters are unlocked and which one is selected.
class OwnedCharactersService extends ChangeNotifier {
  OwnedCharactersService(this._storage, this._coins);

  final StorageService _storage;
  final CoinService _coins;

  final Set<String> _unlocked = {};
  String _selectedId = CharactersData.roster.first.id;

  Set<String> get unlocked => _unlocked;
  String get selectedId => _selectedId;

  Character get selected =>
      CharactersData.roster.firstWhere((c) => c.id == _selectedId,
          orElse: () => CharactersData.roster.first);

  Future<void> load() async {
    final list = _storage.getStringList(StorageKeys.unlockedCharacters);
    _unlocked.clear();
    _unlocked.add(CharactersData.roster.first.id);
    if (list != null) _unlocked.addAll(list);
    final sel = _storage.getString(StorageKeys.selectedCharacter);
    if (sel != null && _unlocked.contains(sel)) _selectedId = sel;
    notifyListeners();
  }

  bool isUnlocked(Character c) =>
      c.isFree || _unlocked.contains(c.id);

  /// Unlocks a character, deducting its price from the coin balance.
  /// Returns true on success. Plays the unlock flow via [onUnlocked].
  Future<bool> unlock(Character c) async {
    if (isUnlocked(c)) return true;
    final ok = await _coins.spendCoins(c.price);
    if (!ok) return false;
    _unlocked.add(c.id);
    await _storage.setStringList(
        StorageKeys.unlockedCharacters, _unlocked.toList());
    notifyListeners();
    return true;
  }

  Future<void> select(Character c) async {
    if (!isUnlocked(c)) return;
    _selectedId = c.id;
    await _storage.setString(StorageKeys.selectedCharacter, c.id);
    notifyListeners();
  }

  void reset() {
    _unlocked.clear();
    _unlocked.add(CharactersData.roster.first.id);
    _selectedId = CharactersData.roster.first.id;
    notifyListeners();
  }
}
