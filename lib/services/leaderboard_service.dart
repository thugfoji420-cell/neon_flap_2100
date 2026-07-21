import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

/// A locally persisted personal-best run. Entries are keyed by difficulty so
/// guest play, offline sessions, and cloud migration can retain independent
/// Easy / Normal / Hard scores without inventing a global-mode conversion.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.score,
    required this.difficulty,
    required this.characterId,
    required this.date,
  });

  final int score;
  final DifficultyMode difficulty;
  final String characterId;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'score': score,
        'difficulty': difficulty.index,
        'characterId': characterId,
        'date': date.toIso8601String(),
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final rawDifficulty = json['difficulty'];
    final difficulty = switch (rawDifficulty) {
      int index when index >= 0 && index < DifficultyMode.values.length =>
        DifficultyMode.values[index],
      String id => DifficultyMode.fromId(id),
      _ => DifficultyMode.normal,
    };
    final rawDate = json['date'] as String?;
    return LeaderboardEntry(
      score: ((json['score'] as num?)?.toInt() ?? 0).clamp(0, 1 << 31).toInt(),
      difficulty: difficulty,
      characterId: json['characterId'] as String? ?? '',
      date: rawDate == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(rawDate) ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Local personal-best repository. It deliberately stores only the best score
/// for each difficulty; older local rows are compacted during load so they do
/// not grow indefinitely on a guest device.
class LeaderboardService extends ChangeNotifier {
  LeaderboardService(this._storage);

  final StorageService _storage;
  Map<DifficultyMode, LeaderboardEntry> _bestByDifficulty = {};

  List<LeaderboardEntry> get entries => _sortedEntries(_bestByDifficulty);

  int bestScoreFor(DifficultyMode difficulty) =>
      _bestByDifficulty[difficulty]?.score ?? 0;

  LeaderboardEntry? entryFor(DifficultyMode difficulty) =>
      _bestByDifficulty[difficulty];

  Future<void> load() async {
    _bestByDifficulty = bestByDifficultyFromEncoded(
      _storage.getStringList(StorageKeys.leaderboard) ?? const <String>[],
    );
    _mergeExplicitBest(
      DifficultyMode.easy,
      _storage.getInt(StorageKeys.guestEasyBest),
    );
    _mergeExplicitBest(
      DifficultyMode.normal,
      _storage.getInt(StorageKeys.guestNormalBest),
    );
    _mergeExplicitBest(
      DifficultyMode.hard,
      _storage.getInt(StorageKeys.guestHardBest),
    );
    // Compact valid legacy per-run rows into three durable personal bests.
    await _save();
    notifyListeners();
  }

  /// Records only a new personal best. Returns true when the displayed score
  /// changed, allowing callers to avoid unnecessary UI work.
  Future<bool> submit(
    int score,
    DifficultyMode difficulty,
    String characterId,
  ) async {
    if (score <= 0 || score <= bestScoreFor(difficulty)) return false;
    _bestByDifficulty = {
      ..._bestByDifficulty,
      difficulty: LeaderboardEntry(
        score: score,
        difficulty: difficulty,
        characterId: characterId,
        date: DateTime.now(),
      ),
    };
    await _save();
    notifyListeners();
    return true;
  }

  /// Decodes legacy and current JSON rows defensively, then selects the high
  /// score per mode. This is also used by the guest-to-Google merge path.
  static Map<DifficultyMode, LeaderboardEntry> bestByDifficultyFromEncoded(
    Iterable<String> encoded,
  ) {
    final best = <DifficultyMode, LeaderboardEntry>{};
    for (final row in encoded) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is! Map<String, dynamic>) continue;
        final entry = LeaderboardEntry.fromJson(decoded);
        final current = best[entry.difficulty];
        if (entry.score > 0 &&
            (current == null || entry.score > current.score)) {
          best[entry.difficulty] = entry;
        }
      } catch (_) {
        // A corrupt offline row is ignored; it must never break startup.
      }
    }
    return best;
  }

  Future<void> _save() => _storage
      .setStringList(
        StorageKeys.leaderboard,
        entries.map((entry) => jsonEncode(entry.toJson())).toList(),
      )
      .then((_) => Future.wait([
            _saveBest(StorageKeys.guestEasyBest, DifficultyMode.easy),
            _saveBest(StorageKeys.guestNormalBest, DifficultyMode.normal),
            _saveBest(StorageKeys.guestHardBest, DifficultyMode.hard),
          ]));

  void _mergeExplicitBest(DifficultyMode difficulty, int? score) {
    if (score == null || score <= 0) return;
    final current = _bestByDifficulty[difficulty];
    if (current == null || score > current.score) {
      _bestByDifficulty[difficulty] = LeaderboardEntry(
        score: score,
        difficulty: difficulty,
        characterId: '',
        date: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
  }

  Future<bool> _saveBest(String key, DifficultyMode difficulty) {
    final score = bestScoreFor(difficulty);
    return score > 0 ? _storage.setInt(key, score) : _storage.remove(key);
  }

  Future<void> reset() async {
    _bestByDifficulty = {};
    await _storage.remove(StorageKeys.leaderboard);
    await Future.wait([
      _storage.remove(StorageKeys.guestEasyBest),
      _storage.remove(StorageKeys.guestNormalBest),
      _storage.remove(StorageKeys.guestHardBest),
    ]);
    notifyListeners();
  }

  static List<LeaderboardEntry> _sortedEntries(
    Map<DifficultyMode, LeaderboardEntry> entries,
  ) {
    final sorted = entries.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return List.unmodifiable(sorted);
  }
}
