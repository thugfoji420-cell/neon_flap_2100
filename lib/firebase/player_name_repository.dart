import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/firebase/firebase_refs.dart';

/// Full set of player fields written to `users/{uid}` when a player name is
/// claimed or changed. Keeps the profile document in sync with the spec.
///
/// Note: the Firestore field/collection names (`username`, `usernameLower`,
/// `usernames`) are the persisted storage schema and are intentionally left
/// unchanged to remain compatible with existing player documents.
class ProfileData {
  const ProfileData({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.coins = 0,
    this.highScore = 0,
  });

  final String uid;
  final String username;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int coins;
  final int highScore;

  Map<String, dynamic> toDoc(bool isNew) => {
        'uid': uid,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'coins': coins,
        'highScore': highScore,
        'lastLogin': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      };

  ProfileData copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? email,
    String? photoUrl,
    int? coins,
    int? highScore,
  }) =>
      ProfileData(
        uid: uid ?? this.uid,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        coins: coins ?? this.coins,
        highScore: highScore ?? this.highScore,
      );
}

/// Data layer for the player-name system.
///
/// Two documents back a player name:
///   users/{uid}        - full player profile (username, email, ...)
///   usernames/{lower}  - { uid, createdAt }   // uniqueness index only
///
/// Claiming / changing a name is performed inside a single Firestore
/// [Transaction]: it reads the `usernames/{lower}` index first, and only writes
/// when the name is free. This makes duplicate names impossible even under
/// concurrent attempts, because the read+write is atomic.
class PlayerNameRepository {
  PlayerNameRepository(this._refs);

  final FirebaseRefs _refs;

  DocumentReference<Map<String, dynamic>> _playerNameDoc(String lower) =>
      _refs.usernames.doc(lower);

  /// Returns true when [lower] is already taken by a *different* uid.
  /// A doc that points back to [uid] is considered available (their own name).
  Future<bool> isTaken(String lower, {required String uid}) async {
    try {
      final snap = await _playerNameDoc(lower)
          .get()
          .timeout(const Duration(seconds: 10));
      if (!snap.exists) return false;
      final owner = snap.data()?['uid'] as String?;
      return owner != uid;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
            'FIRESTORE ISTAKEN ERROR code=${e.code} message=${e.message}');
      }
      rethrow;
    }
  }

  /// Claims [display] for [uid] inside a transaction. Returns false when the
  /// name is taken by someone else (concurrent or pre-existing).
  Future<bool> claim({
    required ProfileData profile,
    required String lower,
    String? previousLower,
  }) async {
    final playerNameRef = _playerNameDoc(lower);
    final playerRef = _refs.player(profile.uid);

    try {
      await _refs.db.runTransaction((tx) async {
        final existing = await tx.get(playerNameRef);
        if (existing.exists) {
          final owner = existing.data()?['uid'] as String?;
          // Allow keeping your own current name.
          if (owner != profile.uid) {
            throw const _PlayerNameTakenException();
          }
        }

        tx.set(
          playerNameRef,
          {
            'uid': profile.uid,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
        tx.set(playerRef, profile.toDoc(existing.exists == false),
            SetOptions(merge: true));

        if (previousLower != null &&
            previousLower != lower &&
            previousLower.isNotEmpty) {
          tx.delete(_playerNameDoc(previousLower));
        }
      }).timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint(
            'PlayerNameRepository.claim: username=$lower claimed for uid=${profile.uid}');
      }
      return true;
    } on _PlayerNameTakenException {
      return false;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('FIRESTORE CLAIM ERROR code=${e.code} message=${e.message}');
      }
      return false;
    }
  }

  /// Reads the current display name for [uid] (or null).
  Future<String?> currentPlayerName(String uid) async {
    final snap = await _refs.player(uid).get();
    final data = snap.data();
    return (data?['username'] as String?)?.trim();
  }

  /// Reads the current lowercased name for [uid] (or null).
  Future<String?> currentLower(String uid) async {
    final snap = await _refs.player(uid).get();
    final data = snap.data();
    final v = data?['usernameLower'] as String?;
    return v?.trim();
  }
}

/// Internal signal used to abort a transaction when the name is already taken.
class _PlayerNameTakenException implements Exception {
  const _PlayerNameTakenException();
}
