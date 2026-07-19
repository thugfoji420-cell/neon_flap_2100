import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/firebase/firebase_refs.dart';
import 'package:neon_flap1_game/firebase/player_name_repository.dart';
import 'package:neon_flap1_game/firebase/player_name_validator.dart';

/// Result of a player-name claim / change attempt.
enum PlayerNameResult {
  /// Successfully saved.
  success,

  /// Local validation failed (too short, bad characters, blocked word, ...).
  invalid,

  /// The player name is already taken by another player.
  taken,

  /// A network / Firestore error prevented the change. Safe to retry.
  error,
}

/// Orchestrates the player-name lifecycle: validation, uniqueness checks,
/// claiming (first launch) and changing (settings), with a transactional write.
///
/// The service is offline-tolerant: if Firestore is unreachable the failure is
/// reported as [PlayerNameResult.error] and nothing is partially written. It
/// never throws into the UI.
class PlayerNameService {
  PlayerNameService(FirebaseRefs refs, {PlayerNameValidator? validator})
      : _repository = PlayerNameRepository(refs),
        _validator = validator ?? PlayerNameValidator();

  final PlayerNameRepository _repository;
  final PlayerNameValidator _validator;

  PlayerNameValidator get validator => _validator;

  /// Validates [value] locally (no network).
  String? validateFormat(String value) => _validator.validate(value);

  /// Lowercase key used for storage / uniqueness.
  String toLookupKey(String value) => _validator.toLookupKey(value);

  /// Claims a player name for the first time. On success the name is live in
  /// both `users/{uid}` and `usernames/{lower}`.
  Future<PlayerNameResult> claim(ProfileData profile, String value) async {
    final error = _validator.validate(value);
    if (error != null) return PlayerNameResult.invalid;

    final lower = _validator.toLookupKey(value);

    final taken =
        await _safe(() => _repository.isTaken(lower, uid: profile.uid));
    if (taken == null) return PlayerNameResult.error; // network failure
    if (taken) return PlayerNameResult.taken;

    final ok = await _safe(() => _repository.claim(
          profile: profile,
          lower: lower,
        ));
    if (ok != true) return PlayerNameResult.error;
    return PlayerNameResult.success;
  }

  /// Changes an existing player name. Performs the rename inside a transaction
  /// and frees the previous index entry so a duplicate is impossible.
  Future<PlayerNameResult> change(ProfileData profile, String value) async {
    final error = _validator.validate(value);
    if (error != null) return PlayerNameResult.invalid;

    final display = value.trim();
    final lower = _validator.toLookupKey(value);

    final previousLower = await _safe(() => _repository.currentLower(profile.uid));
    // No-op if unchanged.
    if (previousLower != null && previousLower == lower) {
      return PlayerNameResult.success;
    }

    final taken =
        await _safe(() => _repository.isTaken(lower, uid: profile.uid));
    if (taken == null) return PlayerNameResult.error;
    if (taken) return PlayerNameResult.taken;

    final ok = await _safe(() => _repository.claim(
          profile: profile.copyWith(username: display),
          lower: lower,
          previousLower: previousLower,
        ));
    if (ok != true) return PlayerNameResult.error;
    return PlayerNameResult.success;
  }

  /// Runs [fn] and returns null on any error instead of throwing, so the UI
  /// can treat null as "offline / retry".
  static Future<T?> _safe<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      if (kDebugMode) debugPrint('PlayerNameService: network error: $e');
      return null;
    }
  }
}
