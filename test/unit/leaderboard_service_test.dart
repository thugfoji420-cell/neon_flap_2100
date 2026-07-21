import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/services/leaderboard_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LeaderboardService> createService(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final storage = StorageService(await SharedPreferences.getInstance());
    final service = LeaderboardService(storage);
    await service.load();
    return service;
  }

  test('compacts legacy run rows into independent difficulty bests', () async {
    final rows = [
      jsonEncode({
        'score': 12,
        'difficulty': DifficultyMode.easy.index,
        'characterId': 'nova',
        'date': '2026-07-01T00:00:00.000',
      }),
      jsonEncode({
        'score': 37,
        'difficulty': DifficultyMode.easy.index,
        'characterId': 'pulse',
        'date': '2026-07-02T00:00:00.000',
      }),
      jsonEncode({
        'score': 24,
        'difficulty': DifficultyMode.hard.index,
        'characterId': 'volt',
        'date': '2026-07-03T00:00:00.000',
      }),
      '{corrupt row}',
    ];
    final service = await createService({StorageKeys.leaderboard: rows});

    expect(service.bestScoreFor(DifficultyMode.easy), 37);
    expect(service.bestScoreFor(DifficultyMode.normal), 0);
    expect(service.bestScoreFor(DifficultyMode.hard), 24);
    expect(service.entryFor(DifficultyMode.easy)?.characterId, 'pulse');
    expect(service.bestScoreFor(DifficultyMode.easy), 37);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(StorageKeys.guestEasyBest), 37);
    expect(prefs.getInt(StorageKeys.guestHardBest), 24);
  });

  test('lower scores cannot overwrite a difficulty personal best', () async {
    final service = await createService({});

    expect(await service.submit(19, DifficultyMode.normal, 'nova'), isTrue);
    expect(await service.submit(18, DifficultyMode.normal, 'volt'), isFalse);
    expect(await service.submit(26, DifficultyMode.normal, 'pulse'), isTrue);

    final best = service.entryFor(DifficultyMode.normal);
    expect(best?.score, 26);
    expect(best?.characterId, 'pulse');
    expect(service.entries, hasLength(1));
  });

  test('explicit guest mode keys restore independently of encoded rows',
      () async {
    final service = await createService({
      StorageKeys.guestEasyBest: 41,
      StorageKeys.guestNormalBest: 19,
      StorageKeys.guestHardBest: 73,
    });

    expect(service.bestScoreFor(DifficultyMode.easy), 41);
    expect(service.bestScoreFor(DifficultyMode.normal), 19);
    expect(service.bestScoreFor(DifficultyMode.hard), 73);
  });
}
