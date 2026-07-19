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
  static const String bannerAdUnitId = 'ca-app-pub-4514520183755342/6809202498';
  static const String rewardedAdUnitId =
      'ca-app-pub-4514520183755342/7113444507';
  static const String rewardedAdUnitId2 =
      'ca-app-pub-4514520183755342/1765749050';
  static const String appOpenAdUnitId =
      'ca-app-pub-4514520183755342/8159345556';
  static const String interstitialAdUnitId =
      'ca-app-pub-4514520183755342/2631686702';

  /// Base URL used for the privacy / terms documents required by the stores.
  /// GitHub Pages serves from the docs/ folder with .nojekyll (no Jekyll).
  /// Files are served with their actual extensions — each URL must match the
  /// exact filename in the docs/ directory (case-sensitive).
  static const String _baseDocs =
      'https://thugfoji420-cell.github.io/neon_flap_2100';
  static const String privacyPolicyUrl = '$_baseDocs/privacy-policy.html';
  static const String termsOfServiceUrl = '$_baseDocs/terms-of-service.html';
  static const String dataDeletionUrl = '$_baseDocs/data-deletion.html';
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
  static const String pendingCloudCoins = 'nf_pending_cloud_coins';
  static const String coinSyncPending = 'nf_coin_sync_pending';
  static const String playerStats = 'nf_player_stats';
  static const String achievementProgress = 'nf_achievement_progress';
  static const String leaderboard = 'nf_leaderboard';
  static const String completedGames = 'nf_completed_games';
  static const String lastInterstitialGame = 'nf_last_interstitial_game';
  static const String themeMode = 'nf_theme_mode';
  static const String dailyRewardLastClaim = 'nf_daily_reward_last_claim';
  static const String dailyRewardClaimedDay = 'nf_daily_reward_claimed_day';
  static const String dailyRewardClaimedStreak = 'nf_daily_reward_claimed_streak';
  static const String dailyRewardPendingOffline = 'nf_daily_reward_pending_offline';
}
