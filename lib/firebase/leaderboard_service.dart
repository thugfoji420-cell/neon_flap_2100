import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/firebase/firebase_refs.dart';

/// The three time windows the leaderboard can be viewed by.
enum LeaderboardScope { global, weekly, monthly }

/// A single row in a cloud leaderboard.
@immutable
class CloudLeaderboardEntry {
  const CloudLeaderboardEntry({
    required this.uid,
    required this.username,
    required this.score,
    required this.coins,
    required this.avatar,
  });

  final String uid;
  final String username;
  final int score;
  final int coins;
  final String avatar;

  factory CloudLeaderboardEntry.fromDoc(
    String id,
    Map<String, dynamic> data,
  ) =>
      CloudLeaderboardEntry(
        uid: id,
        username: (data['username'] as String?) ?? 'Player',
        score: (data['score'] as num?)?.toInt() ?? 0,
        coins: (data['coins'] as num?)?.toInt() ?? 0,
        avatar: (data['avatar'] as String?) ?? 'nova',
      );
}

/// Reads and writes the global / weekly / monthly leaderboards.
///
/// Each collection keeps a single document per player (id == uid) holding that
/// player's best score. Weekly / monthly documents also carry a [periodId] so a
/// query can return only the current period; the score is reset automatically
/// when a new period begins.
class CloudLeaderboardService {
  CloudLeaderboardService(this._refs);

  final FirebaseRefs _refs;

  /// Simple in-memory TTL cache for leaderboard top() queries. The cache lives
  /// for the app process and is evicted after [_cacheTtl].
  static const Duration _cacheTtl = Duration(seconds: 30);
  final _cache = HashMap<LeaderboardScope, _CachedResult>();
  void _cachePut(LeaderboardScope scope, List<CloudLeaderboardEntry> entries) {
    _cache[scope] = _CachedResult(entries, DateTime.now());
  }
  List<CloudLeaderboardEntry>? _cacheGet(LeaderboardScope scope) {
    final cached = _cache[scope];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.at) > _cacheTtl) {
      _cache.remove(scope);
      return null;
    }
    return cached.entries;
  }

  static String weeklyPeriodId([DateTime? now]) {
    final date = now ?? DateTime.now();
    // ISO-8601 week number.
    final dayOfYear = int.parse(
      DateTime(date.year, date.month, date.day)
          .difference(DateTime(date.year, 1, 1))
          .inDays
          .toString(),
    );
    final week = ((dayOfYear - date.weekday + 10) / 7).floor();
    return '${date.year}-W${week.toString().padLeft(2, '0')}';
  }

  static String monthlyPeriodId([DateTime? now]) {
    final date = now ?? DateTime.now();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Submits a score to all three boards, keeping only the best per window.
  Future<void> submitScore({
    required String uid,
    required String username,
    required int score,
    required int coins,
    required String avatar,
  }) async {
    final base = {
      'username': username,
      'coins': coins,
      'avatar': avatar,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Global: keep the all-time best.
    try {
      final ref = _refs.leaderboard.doc(uid);
      final snap = await ref.get();
      final prev = (snap.data()?['score'] as num?)?.toInt() ?? 0;
      if (score > prev) {
        await ref.set({...base, 'score': score}, SetOptions(merge: true));
      } else {
        await ref.set(base, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('leaderboard(global) submit failed: $e');
    }

    // Weekly & monthly: best within the current period.
    await _submitPeriod(
      _refs.leaderboardWeekly.doc(uid),
      periodId: weeklyPeriodId(),
      base: base,
      score: score,
    );
    await _submitPeriod(
      _refs.leaderboardMonthly.doc(uid),
      periodId: monthlyPeriodId(),
      base: base,
      score: score,
    );
  }

  Future<void> _submitPeriod(
    DocumentReference<Map<String, dynamic>> ref, {
    required String periodId,
    required Map<String, dynamic> base,
    required int score,
  }) async {
    try {
      final snap = await ref.get();
      final data = snap.data();
      final samePeriod = data?['periodId'] == periodId;
      final prev = samePeriod ? (data?['score'] as num?)?.toInt() ?? 0 : 0;
      if (!samePeriod || score > prev) {
        await ref.set({
          ...base,
          'periodId': periodId,
          'score': score,
        }, SetOptions(merge: true));
      } else {
        await ref.set({...base, 'periodId': periodId}, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('leaderboard(period) submit failed: $e');
    }
  }

  /// Fetches the top [limit] rows for a given [scope]. Results are cached
  /// in memory for 30 seconds to avoid redundant Firestore reads when the
  /// user switches tabs or reopens the dialog.
  Future<List<CloudLeaderboardEntry>> top(
    LeaderboardScope scope, {
    int limit = 100,
  }) async {
    final cached = _cacheGet(scope);
    if (cached != null) return cached;
    try {
      Query<Map<String, dynamic>> query;
      switch (scope) {
        case LeaderboardScope.global:
          query = _refs.leaderboard
              .orderBy('score', descending: true)
              .limit(limit);
          break;
        case LeaderboardScope.weekly:
          query = _refs.leaderboardWeekly
              .where('periodId', isEqualTo: weeklyPeriodId())
              .orderBy('score', descending: true)
              .limit(limit);
          break;
        case LeaderboardScope.monthly:
          query = _refs.leaderboardMonthly
              .where('periodId', isEqualTo: monthlyPeriodId())
              .orderBy('score', descending: true)
              .limit(limit);
          break;
      }
      final snap = await query.get();
      final entries = snap.docs
          .map((d) => CloudLeaderboardEntry.fromDoc(d.id, d.data()))
          .toList();
      _cachePut(scope, entries);
      return entries;
    } catch (e) {
      if (kDebugMode) debugPrint('leaderboard.top($scope) failed: $e');
      return const [];
    }
  }
}

/// Timestamped cache entry for a leaderboard scope query.
class _CachedResult {
  _CachedResult(this.entries, this.at);
  final List<CloudLeaderboardEntry> entries;
  final DateTime at;
}
