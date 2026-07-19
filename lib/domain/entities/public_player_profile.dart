class PublicPlayerProfile {
  const PublicPlayerProfile({
    required this.username,
    required this.playerId,
    required this.highestScore,
    required this.level,
    required this.totalGames,
    required this.country,
    required this.achievements,
    required this.currentAvatar,
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
  final List<PublicAchievement> achievements;
  final CharacterSummary currentAvatar;
  final String title;
  final DateTime joinDate;
  final RecentActivity recentActivity;
}

class PublicAchievement {
  const PublicAchievement({
    required this.id,
    required this.title,
    required this.icon,
    required this.target,
    required this.progress,
    required this.claimed,
  });

  final String id;
  final String title;
  final String icon;
  final int target;
  final int progress;
  final bool claimed;
}

class CharacterSummary {
  const CharacterSummary({
    required this.id,
    required this.name,
    required this.primaryHex,
    required this.accentHex,
  });

  final String id;
  final String name;
  final String primaryHex;
  final String accentHex;
}

class RecentActivity {
  const RecentActivity({
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
