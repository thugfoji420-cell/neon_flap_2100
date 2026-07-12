/// Application-wide constants for Neon Flap 2100.
///
/// Centralises every magic number, network id and storage key so the rest of
/// the codebase stays configuration-driven and easy to tweak for balance or
/// store compliance.
library;

class AppConstants {
  const AppConstants._();

  static const String appName = 'Neon Flap 2100';
  static const String appVersion = '1.0.0';

  /// Google AdMob test identifiers. Replace with production ids before release.
  /// Banner appears only during gameplay; rewarded drives the reward screen.
  static const String bannerAdUnitId =
      'ca-app-pub-4514520183755342/6809202498';
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String appOpenAdUnitId =
      'ca-app-pub-4514520183755342/8159345556';

  /// Base URL used for the privacy / terms documents required by the stores.
  static const String privacyPolicyUrl =
      'https://example.com/neon-flap-2100/privacy';
  static const String termsOfServiceUrl =
      'https://example.com/neon-flap-2100/terms';
}

/// Keys used for persistent local storage (SharedPreferences).
class StorageKeys {
  const StorageKeys._();

  static const String coins = 'nf_total_coins';
  static const String bestScore = 'nf_best_score';
  static const String unlockedCharacters = 'nf_unlocked_characters';
  static const String selectedCharacter = 'nf_selected_character';
  static const String hasSeenAppOpenAd = 'nf_has_seen_app_open_ad';
  static const String settings = 'nf_settings';
  static const String pendingRewardedCoins = 'nf_pending_rewarded_coins';
  static const String playerStats = 'nf_player_stats';
  static const String achievementProgress = 'nf_achievement_progress';
  static const String leaderboard = 'nf_leaderboard';
}
