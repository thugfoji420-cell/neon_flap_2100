import 'dart:convert';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.rewardCoins,
    this.characterUnlockId,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final int target;
  final int rewardCoins;
  final String? characterUnlockId;

  Achievement copyWithProgress(int progress) =>
      Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        target: target,
        rewardCoins: rewardCoins,
        characterUnlockId: characterUnlockId,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'target': target,
    'rewardCoins': rewardCoins,
    'characterUnlockId': characterUnlockId,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    icon: json['icon'] as String,
    target: json['target'] as int,
    rewardCoins: json['rewardCoins'] as int,
    characterUnlockId: json['characterUnlockId'] as String?,
  );
}

class AchievementProgress {
  const AchievementProgress({
    required this.achievementId,
    required this.progress,
    required this.claimed,
  });

  final String achievementId;
  final int progress;
  final bool claimed;

  Map<String, dynamic> toJson() => {
    'achievementId': achievementId,
    'progress': progress,
    'claimed': claimed,
  };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        achievementId: json['achievementId'] as String,
        progress: json['progress'] as int,
        claimed: json['claimed'] as bool,
      );
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.achievement,
    required this.statKey,
  });

  final Achievement achievement;
  final String statKey;

  static const all = <AchievementDefinition>[
    AchievementDefinition(
      achievement: Achievement(
        id: 'first_flight',
        title: 'First Flight',
        description: 'Complete your first run.',
        icon: '🚀',
        target: 1,
        rewardCoins: 50,
      ),
      statKey: 'gamesPlayed',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'high_flyer',
        title: 'High Flyer',
        description: 'Score 50 points in a single run.',
        icon: '🌟',
        target: 50,
        rewardCoins: 100,
      ),
      statKey: 'bestScore',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'marathon',
        title: 'Marathon',
        description: 'Score 150 points in a single run.',
        icon: '🏆',
        target: 150,
        rewardCoins: 250,
      ),
      statKey: 'bestScore',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'coin_collector',
        title: 'Coin Collector',
        description: 'Collect 100 coins total.',
        icon: '🪙',
        target: 100,
        rewardCoins: 150,
      ),
      statKey: 'totalCoinsCollected',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'veteran',
        title: 'Veteran',
        description: 'Play 25 games.',
        icon: '🎖️',
        target: 25,
        rewardCoins: 300,
      ),
      statKey: 'gamesPlayed',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'legend',
        title: 'Legend',
        description: 'Score 500 points in a single run.',
        icon: '👑',
        target: 500,
        rewardCoins: 500,
      ),
      statKey: 'bestScore',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'bronze_flyer',
        title: 'Bronze Flyer',
        description: 'Score 250 points in a single run.',
        icon: '🥉',
        target: 250,
        rewardCoins: 200,
      ),
      statKey: 'bestScore',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'silver_collector',
        title: 'Silver Collector',
        description: 'Collect 500 coins total.',
        icon: '🥈',
        target: 500,
        rewardCoins: 300,
      ),
      statKey: 'totalCoinsCollected',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'bronze_gamer',
        title: 'Bronze Gamer',
        description: 'Play 50 games.',
        icon: '🎮',
        target: 50,
        rewardCoins: 250,
      ),
      statKey: 'gamesPlayed',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'gold_flyer',
        title: 'Gold Flyer',
        description: 'Score 1000 points in a single run.',
        icon: '🥇',
        target: 1000,
        rewardCoins: 500,
      ),
      statKey: 'bestScore',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'platinum_flyer',
        title: 'Platinum Flyer',
        description: 'Score 2500 points in a single run.',
        icon: '💎',
        target: 2500,
        rewardCoins: 1500,
      ),
      statKey: 'bestScore',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'gold_collector',
        title: 'Gold Collector',
        description: 'Collect 2000 coins total.',
        icon: '💰',
        target: 2000,
        rewardCoins: 800,
      ),
      statKey: 'totalCoinsCollected',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'diamond_collector',
        title: 'Diamond Collector',
        description: 'Collect 10000 coins total.',
        icon: '🏅',
        target: 10000,
        rewardCoins: 2000,
      ),
      statKey: 'totalCoinsCollected',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'silver_gamer',
        title: 'Silver Gamer',
        description: 'Play 100 games.',
        icon: '🎯',
        target: 100,
        rewardCoins: 1000,
      ),
      statKey: 'gamesPlayed',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'gold_gamer',
        title: 'Gold Gamer',
        description: 'Play 500 games.',
        icon: '🏆',
        target: 500,
        rewardCoins: 5000,
      ),
      statKey: 'gamesPlayed',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'platinum_gamer',
        title: 'Platinum Gamer',
        description: 'Play 1000 games.',
        icon: '👑',
        target: 1000,
        rewardCoins: 20000,
      ),
      statKey: 'gamesPlayed',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'score_hoarder',
        title: 'Score Hoarder',
        description: 'Collect 5000 total score points across all runs.',
        icon: '📊',
        target: 5000,
        rewardCoins: 1500,
      ),
      statKey: 'totalScoreAll',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'score_tycoon',
        title: 'Score Tycoon',
        description: 'Collect 50000 total score points across all runs.',
        icon: '📈',
        target: 50000,
        rewardCoins: 10000,
      ),
      statKey: 'totalScoreAll',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'flap_apprentice',
        title: 'Flap Apprentice',
        description: 'Flap 500 times total.',
        icon: '🪽',
        target: 500,
        rewardCoins: 300,
      ),
      statKey: 'totalFlaps',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'flap_master',
        title: 'Flap Master',
        description: 'Flap 5000 times total.',
        icon: '🕊️',
        target: 5000,
        rewardCoins: 1500,
      ),
      statKey: 'totalFlaps',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'flap_legend',
        title: 'Flap Legend',
        description: 'Flap 50000 times total.',
        icon: '🦅',
        target: 50000,
        rewardCoins: 10000,
      ),
      statKey: 'totalFlaps',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'coin_rush',
        title: 'Coin Rush',
        description: 'Collect 50 coins in a single run.',
        icon: '💨',
        target: 50,
        rewardCoins: 300,
      ),
      statKey: 'maxCoinsSingleRun',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'coin_storm',
        title: 'Coin Storm',
        description: 'Collect 200 coins in a single run.',
        icon: '⛈️',
        target: 200,
        rewardCoins: 800,
      ),
      statKey: 'maxCoinsSingleRun',
    ),
    AchievementDefinition(
      achievement: Achievement(
        id: 'coin_typhoon',
        title: 'Coin Typhoon',
        description: 'Collect 1000 coins in a single run.',
        icon: '🌪️',
        target: 1000,
        rewardCoins: 3000,
      ),
      statKey: 'maxCoinsSingleRun',
    ),
  ];
}

class PlayerStats {
  const PlayerStats({
    this.gamesPlayed = 0,
    this.bestScore = 0,
    this.totalCoinsCollected = 0,
    this.totalFlaps = 0,
    this.totalScoreAll = 0,
    this.maxCoinsSingleRun = 0,
  });

  final int gamesPlayed;
  final int bestScore;
  final int totalCoinsCollected;
  final int totalFlaps;
  final int totalScoreAll;
  final int maxCoinsSingleRun;

  PlayerStats copyWith({
    int? gamesPlayed,
    int? bestScore,
    int? totalCoinsCollected,
    int? totalFlaps,
    int? totalScoreAll,
    int? maxCoinsSingleRun,
  }) => PlayerStats(
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    bestScore: bestScore ?? this.bestScore,
    totalCoinsCollected: totalCoinsCollected ?? this.totalCoinsCollected,
    totalFlaps: totalFlaps ?? this.totalFlaps,
    totalScoreAll: totalScoreAll ?? this.totalScoreAll,
    maxCoinsSingleRun: maxCoinsSingleRun ?? this.maxCoinsSingleRun,
  );

  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'bestScore': bestScore,
    'totalCoinsCollected': totalCoinsCollected,
    'totalFlaps': totalFlaps,
    'totalScoreAll': totalScoreAll,
    'maxCoinsSingleRun': maxCoinsSingleRun,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    gamesPlayed: json['gamesPlayed'] as int? ?? 0,
    bestScore: json['bestScore'] as int? ?? 0,
    totalCoinsCollected: json['totalCoinsCollected'] as int? ?? 0,
    totalFlaps: json['totalFlaps'] as int? ?? 0,
    totalScoreAll: json['totalScoreAll'] as int? ?? 0,
    maxCoinsSingleRun: json['maxCoinsSingleRun'] as int? ?? 0,
  );
}

class AchievementService {
  AchievementService(this._storage);

  final StorageService _storage;

  PlayerStats _stats = const PlayerStats();
  final Map<String, AchievementProgress> _progress = {};

  PlayerStats get stats => _stats;
  Map<String, AchievementProgress> get progress => Map.unmodifiable(_progress);

  Future<void> load() async {
    final raw = _storage.getString(StorageKeys.playerStats);
    if (raw != null) {
      try {
        _stats = PlayerStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _stats = const PlayerStats();
      }
    }
    final list = _storage.getStringList(StorageKeys.achievementProgress);
    _progress.clear();
    if (list != null) {
      for (final entry in list) {
        try {
          final map = jsonDecode(entry) as Map<String, dynamic>;
          final p = AchievementProgress.fromJson(map);
          _progress[p.achievementId] = p;
        } catch (_) {
          // skip corrupt entries
        }
      }
    }
  }

  Future<void> _saveProgress() async {
    await _storage.setStringList(
      StorageKeys.achievementProgress,
      _progress.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _saveStats() async {
    await _storage.setString(
      StorageKeys.playerStats,
      jsonEncode(_stats.toJson()),
    );
  }

  Future<void> recordRun(int score, int coinsCollected, int totalFlaps) async {
    final newBest = score > _stats.bestScore ? score : _stats.bestScore;
    final newTotal = _stats.totalCoinsCollected + coinsCollected;
    final newTotalScore = _stats.totalScoreAll + score;
    final newMaxCoins = coinsCollected > _stats.maxCoinsSingleRun
        ? coinsCollected
        : _stats.maxCoinsSingleRun;
    _stats = _stats.copyWith(
      gamesPlayed: _stats.gamesPlayed + 1,
      bestScore: newBest,
      totalCoinsCollected: newTotal,
      totalFlaps: _stats.totalFlaps + totalFlaps,
      totalScoreAll: newTotalScore,
      maxCoinsSingleRun: newMaxCoins,
    );
    await _saveStats();
  }

  int getProgress(String statKey) {
    switch (statKey) {
      case 'gamesPlayed':
        return _stats.gamesPlayed;
      case 'bestScore':
        return _stats.bestScore;
      case 'totalCoinsCollected':
        return _stats.totalCoinsCollected;
      case 'totalFlaps':
        return _stats.totalFlaps;
      case 'totalScoreAll':
        return _stats.totalScoreAll;
      case 'maxCoinsSingleRun':
        return _stats.maxCoinsSingleRun;
      default:
        return 0;
    }
  }

  Future<List<(Achievement, int, bool)>> evaluateAndClaim(
    CoinService coins,
    OwnedCharactersService owned,
  ) async {
    final results = <(Achievement, int, bool)>[];
    for (final def in AchievementDefinition.all) {
      final current = getProgress(def.statKey);
      final existing = _progress[def.achievement.id];
      final prevProgress = existing?.progress ?? 0;
      final claimed = existing?.claimed ?? false;

      if (claimed) {
        results.add((def.achievement, current, true));
        continue;
      }

      final newProgress = current >= def.achievement.target
          ? def.achievement.target
          : current;

      if (newProgress != prevProgress) {
        _progress[def.achievement.id] = AchievementProgress(
          achievementId: def.achievement.id,
          progress: newProgress,
          claimed: false,
        );
        await _saveProgress();
      }

      final shouldClaim = newProgress >= def.achievement.target && !claimed;
      if (shouldClaim) {
        if (def.achievement.rewardCoins > 0) {
          await coins.addCoins(def.achievement.rewardCoins);
        }
        final unlockId = def.achievement.characterUnlockId;
        if (unlockId != null) {
          final character = CharactersData.byId(unlockId);
          if (!owned.isUnlocked(character)) {
            final list = _storage.getStringList(StorageKeys.unlockedCharacters) ?? [];
            if (!list.contains(character.id)) {
              list.add(character.id);
              await _storage.setStringList(StorageKeys.unlockedCharacters, list);
            }
          }
        }
        _progress[def.achievement.id] = AchievementProgress(
          achievementId: def.achievement.id,
          progress: newProgress,
          claimed: true,
        );
        await _saveProgress();
        results.add((def.achievement, newProgress, true));
      } else {
        results.add((def.achievement, newProgress, false));
      }
    }
    return results;
  }

  Future<void> reset() async {
    _stats = const PlayerStats();
    _progress.clear();
    await _saveStats();
    await _saveProgress();
  }
}
