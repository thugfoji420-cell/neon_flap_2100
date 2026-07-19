import 'dart:convert';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

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

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        score: json['score'] as int,
        difficulty: DifficultyMode.values[json['difficulty'] as int],
        characterId: json['characterId'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class LeaderboardService {
  LeaderboardService(this._storage);

  final StorageService _storage;

  List<LeaderboardEntry> _entries = [];

  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final raw = _storage.getStringList(StorageKeys.leaderboard);
    if (raw != null) {
      try {
        _entries = raw
            .map((e) => LeaderboardEntry.fromJson(
                jsonDecode(e) as Map<String, dynamic>))
            .toList();
        _entries.sort((a, b) => b.score.compareTo(a.score));
      } catch (_) {
        _entries = [];
      }
    }
  }

  Future<void> submit(int score, DifficultyMode difficulty, String characterId) async {
    final entry = LeaderboardEntry(
      score: score,
      difficulty: difficulty,
      characterId: characterId,
      date: DateTime.now(),
    );
    _entries.add(entry);
    _entries.sort((a, b) => b.score.compareTo(a.score));
    if (_entries.length > 20) {
      _entries = _entries.take(20).toList();
    }
    await _save();
  }

  Future<void> _save() async {
    final json = _entries.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.leaderboard, json);
  }

  Future<void> reset() async {
    _entries = [];
    await _storage.remove(StorageKeys.leaderboard);
  }
}
