import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:neon_flap1_game/firebase/firebase_refs.dart';

/// Data layer for a single player's Firestore documents.
///
/// Owns:
///   players/{uid}       - profile + stats
///   inventory/{uid}     - owned & selected characters
///   achievements/{uid}  - unlocked achievement flags
///   settings/{uid}      - audio / vibration / language
///   cloud_save/{uid}    - lightweight save snapshot
///
/// Every write is best-effort and wrapped so a network failure never breaks the
/// game; local SharedPreferences remains the source of truth while offline.
class PlayerService {
  PlayerService(this._refs);

  final FirebaseRefs _refs;

  String? _uid;
  Map<String, dynamic> _profile = {};

  /// True when the `players/{uid}` document already existed in Firestore before
  /// the most recent [loadOrCreate]. Used to distinguish a returning player
  /// (who skips username creation) from a brand-new Google account.
  bool profileExisted = false;

  Map<String, dynamic> get profile => Map.unmodifiable(_profile);

  String? get username => _profile['username'] as String?;

  bool get hasUsername => (username?.trim().isNotEmpty) ?? false;

  bool get hasDefaultUsername {
    final name = username;
    if (name == null) return false;
    final trimmed = name.trim();
    return RegExp(r'^Player_[A-Z0-9]{4}$').hasMatch(trimmed);
  }

  /// Loads (or creates) the player profile document. Returns the profile map.
  /// [profileExisted] records whether the cloud document was already present so
  /// callers can decide whether a username still needs to be chosen.
  Future<Map<String, dynamic>> loadOrCreate(
    String uid, {
    required int localCoins,
    required int localHighScore,
    required String avatarId,
  }) async {
    _uid = uid;
    try {
      final doc = await _refs.player(uid).get();
      if (doc.exists) {
        profileExisted = true;
        _profile = doc.data() ?? {};
        // Touch last login without clobbering anything else.
        await _refs.player(uid).set({
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        profileExisted = false;
        final defaultName = _defaultUsername(uid);
        _profile = {
          'username': defaultName,
          'usernameLower': defaultName.toLowerCase(),
          'coins': localCoins,
          'highScore': localHighScore,
          'bestDistance': 0,
          'level': 1,
          'xp': 0,
          'totalGames': 0,
          'wins': 0,
          'deaths': 0,
          'difficulty': 'Normal',
          'avatar': avatarId,
          'country': WidgetsBinding
                  .instance.platformDispatcher.locale.countryCode ??
              'XX',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        };
        await _refs.player(uid).set(_profile, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('PlayerService.loadOrCreate failed: $e');
    }
    return _profile;
  }

  String _defaultUsername(String uid) {
    final suffix = uid.length >= 4 ? uid.substring(0, 4) : uid;
    return 'Player_${suffix.toUpperCase()}';
  }

  /// Persists a player-chosen username to the profile and mirrors it to the
  /// leaderboard entries so the name shown there stays in sync.
  Future<void> setUsername(String name) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    final clean = name.trim();
    if (clean.isEmpty) return;
    _profile['username'] = clean;
    _profile['usernameLower'] = clean.toLowerCase();
    try {
      await _refs.player(currentUid).set({
        'username': clean,
        'usernameLower': clean.toLowerCase(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('PlayerService.setUsername failed: $e');
    }
  }

  /// Updates the in-memory username fields without writing to Firestore.
  /// Used after a successful username claim to keep the UI in sync immediately.
  void updateUsername(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _profile['username'] = clean;
    _profile['usernameLower'] = clean.toLowerCase();
  }

  Future<void> syncCoins(int coins) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    _profile['coins'] = coins;
    try {
      await _refs.player(currentUid).set({'coins': coins}, SetOptions(merge: true));
    } catch (_) {/* offline-tolerant */}
  }

  Future<void> syncHighScore(int highScore) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    final current = (_profile['highScore'] as num?)?.toInt() ?? 0;
    if (highScore <= current) return;
    _profile['highScore'] = highScore;
    try {
      await _refs.player(currentUid).set(
        {'highScore': highScore},
        SetOptions(merge: true),
      );
    } catch (_) {/* offline-tolerant */}
  }

  /// Updates aggregate stats after a run. [xpGained] contributes to a simple
  /// level curve (100 xp per level).
  Future<void> recordRun({
    required int score,
    required int coinsEarned,
    required String difficulty,
    required String avatarId,
  }) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    final totalGames = ((_profile['totalGames'] as num?)?.toInt() ?? 0) + 1;
    final deaths = ((_profile['deaths'] as num?)?.toInt() ?? 0) + 1;
    final xp = ((_profile['xp'] as num?)?.toInt() ?? 0) + score + coinsEarned;
    final level = 1 + (xp ~/ 100);
    _profile.addAll({
      'totalGames': totalGames,
      'deaths': deaths,
      'xp': xp,
      'level': level,
      'difficulty': difficulty,
      'avatar': avatarId,
    });
    try {
      await _refs.player(currentUid).set({
        'totalGames': totalGames,
        'deaths': deaths,
        'xp': xp,
        'level': level,
        'difficulty': difficulty,
        'avatar': avatarId,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* offline-tolerant */}
  }

  /// inventory/{uid}
  Future<void> syncInventory({
    required String selectedBird,
    required List<String> ownedBirds,
  }) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    try {
      await _refs.inventory.doc(currentUid).set({
        'selectedBird': selectedBird,
        'ownedBirds': ownedBirds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* offline-tolerant */}
  }

  /// achievements/{uid}
  Future<void> syncAchievements(Map<String, bool> unlocked) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    try {
      await _refs.achievements.doc(currentUid).set({
        ...unlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* offline-tolerant */}
  }

  /// settings/{uid}
  Future<void> syncSettings({
    required bool music,
    required bool sound,
    required bool vibration,
    String language = 'English',
  }) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    try {
      await _refs.settings.doc(currentUid).set({
        'music': music,
        'sound': sound,
        'vibration': vibration,
        'language': language,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* offline-tolerant */}
  }

  /// cloud_save/{uid} - lightweight snapshot used for restore.
  Future<void> syncCloudSave({
    required int coins,
    required int highScore,
    int checkpoint = 0,
  }) async {
    final currentUid = _uid;
    if (currentUid == null) return;
    try {
      await _refs.cloudSave.doc(currentUid).set({
        'coins': coins,
        'highScore': highScore,
        'checkpoint': checkpoint,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* offline-tolerant */}
  }

  /// Resets in-memory state after account deletion or sign-out.
  void reset() {
    _uid = null;
    _profile = {};
    profileExisted = false;
  }
}
