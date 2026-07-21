import '../../domain/entities/public_player_profile.dart';

class PublicProfileModel {
  const PublicProfileModel({
    required this.username,
    required this.playerId,
    required this.highestScore,
    required this.level,
    required this.totalGames,
    required this.country,
    required this.achievements,
    required this.currentAvatarId,
    required this.title,
    required this.joinDate,
    required this.recentActivity,
  });

  final String username;
  final String playerId;
  final int highestScore;
  final int level;
  final int totalGames;
  final String country;
  final List<PublicAchievementModel> achievements;
  final String currentAvatarId;
  final String title;
  final DateTime joinDate;
  final RecentActivityModel recentActivity;

  factory PublicProfileModel.fromFirestore(
    String uid,
    Map<String, dynamic> playerDoc,
    Map<String, dynamic> leaderboardDoc,
    Map<String, dynamic> achievementsDoc,
  ) {
    final now = DateTime.now();
    final createdRaw = playerDoc['createdAt'];
    DateTime joinDate;
    if (createdRaw is DateTime) {
      joinDate = createdRaw;
    } else if (createdRaw != null) {
      try {
        joinDate = DateTime.parse(createdRaw.toString());
      } catch (_) {
        joinDate = now;
      }
    } else {
      joinDate = now;
    }

    final level = ((playerDoc['level'] as num?)?.toInt() ?? 1).clamp(1, 9999);
    final xp = (playerDoc['xp'] as num?)?.toInt() ?? 0;
    final title = _deriveTitle(level, xp);

    final avatarId = (playerDoc['avatar'] as String?) ?? 'nova';
    final country = (playerDoc['country'] as String?) ?? 'XX';

    final highestScore = (leaderboardDoc['score'] as num?)?.toInt() ?? 0;

    final achievements = <PublicAchievementModel>[];
    if (achievementsDoc.isNotEmpty) {
      achievementsDoc.forEach((key, value) {
        if (key == 'updatedAt') return;
        final claimed = (value as bool?) ?? false;
        achievements.add(PublicAchievementModel(id: key, claimed: claimed));
      });
    }

    final totalGames = (playerDoc['totalGames'] as num?)?.toInt() ?? 0;
    final totalFlaps = (playerDoc['totalFlaps'] as num?)?.toInt() ??
        (playerDoc['xp'] as num?)?.toInt() ??
        0;
    final totalScoreAll = (playerDoc['totalScoreAll'] as num?)?.toInt() ??
        (playerDoc['totalScore'] as num?)?.toInt() ??
        0;
    final maxCoinsSingleRun =
        (playerDoc['maxCoinsSingleRun'] as num?)?.toInt() ??
            (playerDoc['bestCoins'] as num?)?.toInt() ??
            0;

    DateTime lastActive;
    final lastLoginRaw = playerDoc['lastLogin'];
    final updatedAtRaw = leaderboardDoc['updatedAt'];
    if (lastLoginRaw is DateTime) {
      lastActive = lastLoginRaw;
    } else if (updatedAtRaw is DateTime) {
      lastActive = updatedAtRaw;
    } else if (lastLoginRaw != null) {
      try {
        lastActive = DateTime.parse(lastLoginRaw.toString());
      } catch (_) {
        lastActive = joinDate;
      }
    } else if (updatedAtRaw != null) {
      try {
        lastActive = DateTime.parse(updatedAtRaw.toString());
      } catch (_) {
        lastActive = joinDate;
      }
    } else {
      lastActive = joinDate;
    }

    return PublicProfileModel(
      username: (playerDoc['username'] as String?) ?? 'Player',
      playerId: _shortUid(uid),
      highestScore: highestScore,
      level: level,
      totalGames: totalGames,
      country: country,
      achievements: achievements,
      currentAvatarId: avatarId,
      title: title,
      joinDate: joinDate,
      recentActivity: RecentActivityModel(
        lastActive: lastActive,
        totalRuns: totalGames,
        totalFlaps: totalFlaps,
        totalScoreAll: totalScoreAll,
        maxCoinsSingleRun: maxCoinsSingleRun,
      ),
    );
  }

  static String _shortUid(String uid) {
    if (uid.length <= 8) return uid.toUpperCase();
    return '${uid.substring(0, 4).toUpperCase()}-${uid.substring(uid.length - 4).toUpperCase()}';
  }

  static String _deriveTitle(int level, int xp) {
    if (level >= 100) return 'LEGEND';
    if (level >= 75) return 'PHANTOM';
    if (level >= 50) return 'AGENT';
    if (level >= 30) return 'OPERATIVE';
    if (level >= 15) return 'RUNNER';
    if (level >= 5) return 'PILOT';
    return 'ROOKIE';
  }

  PublicPlayerProfile toEntity(List<PublicAchievement> resolvedAchievements) {
    return PublicPlayerProfile(
      username: username,
      playerId: playerId,
      highestScore: highestScore,
      level: level,
      totalGames: totalGames,
      country: country,
      achievements: resolvedAchievements,
      currentAvatar: CharacterSummary(
        id: currentAvatarId,
        name: currentAvatarId
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' '),
        primaryHex: currentAvatarId,
        accentHex: currentAvatarId,
      ),
      title: title,
      joinDate: joinDate,
      recentActivity: RecentActivity(
        lastActive: recentActivity.lastActive,
        totalRuns: recentActivity.totalRuns,
        totalFlaps: recentActivity.totalFlaps,
        totalScoreAll: recentActivity.totalScoreAll,
        maxCoinsSingleRun: recentActivity.maxCoinsSingleRun,
      ),
    );
  }
}

class PublicAchievementModel {
  const PublicAchievementModel({
    required this.id,
    required this.claimed,
  });

  final String id;
  final bool claimed;
}

class RecentActivityModel {
  const RecentActivityModel({
    required this.lastActive,
    required this.totalRuns,
    required this.totalFlaps,
    required this.totalScoreAll,
    required this.maxCoinsSingleRun,
  });

  final DateTime lastActive;
  final int totalRuns;
  final int totalFlaps;
  final int totalScoreAll;
  final int maxCoinsSingleRun;
}
