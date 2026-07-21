import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/firebase/firebase_refs.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';

/// A best-score row for one selected difficulty. The canonical Firestore
/// document remains `leaderboard/{uid}` so existing authenticated access rules
/// continue to apply; its `difficultyScores.{mode}` map stores each board.
@immutable
class CloudLeaderboardEntry {
  const CloudLeaderboardEntry({
    required this.uid,
    required this.username,
    required this.score,
    required this.selectedCharacterId,
  });

  final String uid;
  final String username;
  final int score;
  final String selectedCharacterId;

  factory CloudLeaderboardEntry.fromDoc(
    String id,
    Map<String, dynamic> data,
    DifficultyMode difficulty,
  ) {
    final scores = data['difficultyScores'];
    final scoreData =
        scores is Map ? scores[difficulty.id] as Map<Object?, Object?>? : null;
    return CloudLeaderboardEntry(
      uid: (scoreData?['uid'] as String?) ?? (data['uid'] as String?) ?? id,
      username: (data['username'] as String?) ??
          (scoreData?['username'] as String?) ??
          'Player',
      score: (scoreData?['score'] as num?)?.toInt() ?? 0,
      selectedCharacterId: (scoreData?['selectedCharacterId'] as String?) ??
          (data['selectedCharacterId'] as String?) ??
          // `avatar` supports old rows without treating their global score as
          // a score for any one difficulty.
          (data['avatar'] as String?) ??
          'nova',
    );
  }
}

@immutable
class CloudLeaderboardResult {
  const CloudLeaderboardResult({
    required this.entries,
    this.errorMessage,
  });

  final List<CloudLeaderboardEntry> entries;
  final String? errorMessage;
  bool get hasError => errorMessage != null;
}

/// Reads and writes all-time difficulty boards. `leaderboard/{uid}` holds a
/// nested record for every mode so no new unauthenticated collection/rule is
/// required, and a score can only replace its own mode's personal best.
class CloudLeaderboardService {
  CloudLeaderboardService(this._refs);

  final FirebaseRefs _refs;

  static const Duration _cacheTtl = Duration(seconds: 30);
  final _cache = HashMap<DifficultyMode, _CachedResult>();

  void _cachePut(
    DifficultyMode difficulty,
    List<CloudLeaderboardEntry> entries,
  ) {
    _cache[difficulty] = _CachedResult(entries, DateTime.now());
  }

  List<CloudLeaderboardEntry>? _cacheGet(DifficultyMode difficulty) {
    final cached = _cache[difficulty];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.at) > _cacheTtl) {
      _cache.remove(difficulty);
      return null;
    }
    return cached.entries;
  }

  /// Atomically writes only a higher score for [difficulty]. Lower scores do
  /// not change a board row, preventing gameplay restarts from downgrading a
  /// personal best or overwriting its selected-character snapshot.
  Future<void> submitScore({
    required String uid,
    required String username,
    required int score,
    required DifficultyMode difficulty,
    required String selectedCharacterId,
  }) async {
    if (score <= 0 || uid.isEmpty) return;
    final ref = _refs.leaderboard.doc(uid);
    var changed = false;
    try {
      await _refs.db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        final scores = data?['difficultyScores'];
        final scoreMap = scores is Map
            ? scores[difficulty.id] as Map<Object?, Object?>?
            : null;
        final previous = (scoreMap?['score'] as num?)?.toInt() ?? 0;

        final playerFields = <String, Object?>{
          'uid': uid,
          'username': username,
          'selectedCharacterId': selectedCharacterId,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (score <= previous) {
          if (snapshot.exists) transaction.update(ref, playerFields);
          return;
        }

        changed = true;
        final scoreFields = <String, Object?>{
          'uid': uid,
          'username': username,
          'score': score,
          'selectedCharacterId': selectedCharacterId,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (snapshot.exists) {
          transaction.update(ref, {
            ...playerFields,
            'difficultyScores.${difficulty.id}': scoreFields,
          });
        } else {
          transaction.set(ref, {
            ...playerFields,
            'difficultyScores': {difficulty.id: scoreFields},
          });
        }
      });
      if (changed) _cache.remove(difficulty);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('leaderboard(${difficulty.id}) submit failed: $error');
      }
    }
  }

  /// Mirrors a renamed profile into existing difficulty records only. It never
  /// creates a zero-score leaderboard document for a player who has not flown.
  Future<void> updateUsername(
      {required String uid, required String username}) async {
    if (uid.isEmpty || username.trim().isEmpty) return;
    final ref = _refs.leaderboard.doc(uid);
    try {
      final snapshot = await ref.get();
      final scores = snapshot.data()?['difficultyScores'];
      if (!snapshot.exists || scores is! Map) return;
      final updates = <String, Object?>{'username': username.trim()};
      for (final mode in DifficultyMode.values) {
        if (scores[mode.id] is Map) {
          updates['difficultyScores.${mode.id}.username'] = username.trim();
        }
      }
      await ref.update(updates);
      _cache.clear();
    } catch (error) {
      if (kDebugMode) debugPrint('leaderboard username sync failed: $error');
    }
  }

  /// Loads only the active difficulty, rather than issuing three eager reads.
  /// The result keeps a network error distinct from a genuine empty board.
  Future<CloudLeaderboardResult> top(
    DifficultyMode difficulty, {
    int limit = 100,
  }) async {
    final cached = _cacheGet(difficulty);
    if (cached != null) return CloudLeaderboardResult(entries: cached);
    try {
      final field = 'difficultyScores.${difficulty.id}.score';
      final snapshot = await _refs.leaderboard
          .orderBy(field, descending: true)
          .limit(limit)
          .get();
      final entries = snapshot.docs
          .map((document) => CloudLeaderboardEntry.fromDoc(
                document.id,
                document.data(),
                difficulty,
              ))
          .where((entry) => entry.score > 0)
          .toList(growable: false);
      _cachePut(difficulty, entries);
      return CloudLeaderboardResult(entries: entries);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('leaderboard.top(${difficulty.id}) failed: $error');
      }
      return const CloudLeaderboardResult(
        entries: [],
        errorMessage: 'Unable to load rankings right now. Please try again.',
      );
    }
  }
}

class _CachedResult {
  _CachedResult(this.entries, this.at);
  final List<CloudLeaderboardEntry> entries;
  final DateTime at;
}
