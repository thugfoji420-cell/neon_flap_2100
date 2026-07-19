import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/firebase/auth_service.dart';
import 'package:neon_flap1_game/firebase/daily_reward_service.dart';
import 'package:neon_flap1_game/firebase/firebase_refs.dart';
import 'package:neon_flap1_game/firebase/leaderboard_service.dart';
import 'package:neon_flap1_game/firebase/player_service.dart';
import 'package:neon_flap1_game/firebase/player_name_service.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/firebase/player_name_repository.dart';

/// Single entry point that composes all Firebase sub-services and coordinates
/// the sync between local game state and Firestore.
///
/// The game always works offline: if sign-in fails or a write errors, local
/// SharedPreferences remains authoritative and the cloud simply catches up
/// later. Nothing here should ever throw into the UI.
class FirebaseService extends ChangeNotifier {
  FirebaseService(
    FirebaseAuth auth,
    FirebaseFirestore firestore,
    AuthService authService,
  )   : _auth = authService,
        _refs = FirebaseRefs(firestore) {
    _player = PlayerService(_refs);
    _leaderboard = CloudLeaderboardService(_refs);
    _dailyReward = DailyRewardService(_refs);
    _username = PlayerNameService(_refs);
  }

  final AuthService _auth;
  final FirebaseRefs _refs;
  late final PlayerService _player;
  late final CloudLeaderboardService _leaderboard;
  late final DailyRewardService _dailyReward;
  late final PlayerNameService _username;

  bool _initializing = true;

  bool get initializing => _initializing;
  bool get isSignedIn => _auth.isSignedIn;
  String? get uid => _auth.uid;
  String? get error => _auth.error;

  AuthService get auth => _auth;
  PlayerService get player => _player;
  CloudLeaderboardService get leaderboard => _leaderboard;
  DailyRewardService get dailyReward => _dailyReward;
  PlayerNameService get playerNameService => _username;

  /// The player's display name, falling back to a UID-derived default.
  String get playerName => _player.username ?? 'Player';
  bool get hasPlayerName => _player.hasUsername;
  String? get playerNameLower => _player.profile['usernameLower'] as String?;
  bool get hasDefaultPlayerName => _player.hasDefaultUsername;

  /// Builds the [ProfileData] written to Firestore for the current user, using
  /// the authenticated Google account's display name / email / photo and the
  /// best-known coin & high-score values.
  ProfileData profileData(String username, {int coins = 0, int highScore = 0}) {
    final user = _auth.currentUser;
    return ProfileData(
      uid: user?.uid ?? uid ?? '',
      username: username,
      displayName: user?.displayName,
      email: user?.email,
      photoUrl: user?.photoURL,
      coins: coins,
      highScore: highScore,
    );
  }

  /// True when the player still has the auto-generated default name and must
  /// create a real player name before the game continues (first-time users).
  ///
  /// After sign-in we know whether the `players/{uid}` document already existed
  /// in the cloud ([PlayerService.profileExisted]). Returning players skip the
  /// username prompt entirely; only brand-new Google accounts (no existing
  /// document) are routed to the username creation screen.
  bool get needsPlayerName => _player.profileExisted == false || !hasPlayerName || hasDefaultPlayerName;

  Future<bool> get playerNamePromptCompleted async {
    final storage = sl<StorageService>();
    return storage.getBool('player_name_prompt_completed') ?? false;
  }

  Future<void> setPlayerNamePromptCompleted() async {
    final storage = sl<StorageService>();
    await storage.setBool('player_name_prompt_completed', true);
  }

  /// Loads the cloud profile for the currently authenticated user.
  ///
  /// For returning users the `players/{uid}` document already exists: its values
  /// are adopted (coins / high score are taken when higher than the local
  /// values). For brand-new Google accounts the document does not exist yet, so
  /// [playerDocumentExists] is `false` and the caller must show the username
  /// creation screen before the game continues.
  ///
  /// Applies a [bootstrap] result to the local [CoinService], adopting the
  /// higher of cloud vs. local coin and high-score values. Callers that invoke
  /// [bootstrap] directly should pass the returned record through this method
  /// instead of duplicating the merge logic.
  Future<void> applyBootstrap(
    ({int coins, int highScore, bool playerDocumentExists})? result,
    CoinService coins,
  ) async {
    if (result == null) return;
    if (result.coins != coins.coins) {
      await coins.setFromCloud(result.coins);
    }
    if (result.highScore != coins.bestScore) {
      await coins.setBestScoreFromCloud(result.highScore);
    }
  }

  /// Returns a record describing any cloud values that should be applied back
  /// to the local services so the caller can keep everything consistent.
  Future<({int coins, int highScore, bool playerDocumentExists})?> bootstrap({
    required int localCoins,
    required int localHighScore,
    required String avatarId,
  }) async {
    _initializing = true;
    final user = await _auth.restoreSession();
    if (user == null) {
      _initializing = false;
      notifyListeners();
      return null;
    }

    final profile = await _player.loadOrCreate(
      user.uid,
      localCoins: localCoins,
      localHighScore: localHighScore,
      avatarId: avatarId,
    );

    final cloudCoins = (profile['coins'] as num?)?.toInt() ?? 0;
    final cloudHigh = (profile['highScore'] as num?)?.toInt() ?? 0;

    // For an existing profile, always use the cloud value as authoritative.
    // localCoins / localHighScore come from SharedPreferences which is
    // device-wide — when switching accounts the old user's cached values
    // must NOT leak into the new user's balance.
    final mergedCoins =
        _player.profileExisted ? cloudCoins : (cloudCoins > localCoins ? cloudCoins : localCoins);
    final mergedHigh =
        _player.profileExisted ? cloudHigh : (cloudHigh > localHighScore ? cloudHigh : localHighScore);

    // Ensure the cloud reflects the merged (best) values.
    if (mergedCoins != cloudCoins) await _player.syncCoins(mergedCoins);
    if (mergedHigh != cloudHigh) await _player.syncHighScore(mergedHigh);

    _initializing = false;
    notifyListeners();
    return (
      coins: mergedCoins,
      highScore: mergedHigh,
      playerDocumentExists: profile.isNotEmpty && profile['username'] != null,
    );
  }

  Future<PlayerNameResult> setPlayerName(String name) async {
    final currentUid = uid;
    if (currentUid == null) return PlayerNameResult.error;
    final result = await _username.change(profileData(name), name);
    if (result == PlayerNameResult.success) {
      _player.updateUsername(name);
      // Keep leaderboard rows in sync with the chosen name.
      try {
        await _refs.leaderboard.doc(currentUid).set(
          {'username': name.trim()},
          SetOptions(merge: true),
        );
        await _refs.leaderboardWeekly.doc(currentUid).set(
          {'username': name.trim()},
          SetOptions(merge: true),
        );
        await _refs.leaderboardMonthly.doc(currentUid).set(
          {'username': name.trim()},
          SetOptions(merge: true),
        );
      } catch (_) {/* offline-tolerant */}
      refreshPlayerState();
    }
    return result;
  }

  Future<void> syncCoins(int coins) => _player.syncCoins(coins);

  Future<void> syncInventory({
    required String selectedBird,
    required List<String> ownedBirds,
  }) =>
      _player.syncInventory(selectedBird: selectedBird, ownedBirds: ownedBirds);

  Future<void> syncSettings({
    required bool music,
    required bool sound,
    required bool vibration,
  }) =>
      _player.syncSettings(music: music, sound: sound, vibration: vibration);

  /// Called after a run finishes: updates stats, high score, coins, cloud save,
  /// achievements and submits to the leaderboards.
  Future<void> onRunComplete({
    required int score,
    required int coinsEarned,
    required int totalCoins,
    required int bestScore,
    required DifficultyMode mode,
    required String avatarId,
    required Map<String, bool> achievementsUnlocked,
  }) async {
    final currentUid = uid;
    if (currentUid == null) return;
    await _player.recordRun(
      score: score,
      coinsEarned: coinsEarned,
      difficulty: mode.name,
      avatarId: avatarId,
    );
    await _player.syncHighScore(bestScore);
    // Coin balance is not written here — [CoinSyncService] is the sole
    // runtime writer, triggered by every [CoinService.addCoins] call.
    await _player.syncCloudSave(coins: totalCoins, highScore: bestScore);
    if (achievementsUnlocked.isNotEmpty) {
      await _player.syncAchievements(achievementsUnlocked);
    }
    await _leaderboard.submitScore(
      uid: currentUid,
      username: playerName,
      score: score,
      coins: totalCoins,
      avatar: avatarId,
    );
  }

  /// Claims the daily reward, returning the coins granted (0 if unavailable).
  Future<int> claimDailyReward() async {
    final currentUid = uid;
    if (currentUid == null) return 0;
    return _dailyReward.claim(currentUid);
  }

  Future<DailyRewardStatus> dailyRewardStatus() async {
    final currentUid = uid;
    if (currentUid == null) {
      return const DailyRewardStatus(
        day: 1,
        streak: 0,
        canClaim: false,
        rewardCoins: 0,
        lastClaim: null,
      );
    }
    return _dailyReward.status(currentUid);
  }

  /// Permanently deletes the authenticated user's account and all associated
  /// cloud data. Returns null on success, or an error message on failure.
  Future<String?> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return 'No user is currently signed in.';

    final uid = user.uid;
    if (kDebugMode) debugPrint('Starting account deletion for uid=$uid');

    final deleteError = await _deleteCloudData(uid);
    if (deleteError != null) return deleteError;

    final usernameError = await _deleteUsernameIndex();
    if (usernameError != null) return usernameError;

    final authError = await _deleteAuthUser(user, uid);
    if (authError != null) return authError;

    await _clearLocalSession();
    _resetAfterDeletion(uid);

    return null;
  }

  /// Deletes all Firestore documents owned by the player.
  Future<String?> _deleteCloudData(String uid) async {
    final deleteFutures = <Future>[
      _refs.player(uid).delete(),
      _refs.cloudSave.doc(uid).delete(),
      _refs.inventory.doc(uid).delete(),
      _refs.achievements.doc(uid).delete(),
      _refs.dailyRewards.doc(uid).delete(),
      _refs.settings.doc(uid).delete(),
      _refs.leaderboard.doc(uid).delete(),
      _refs.leaderboardWeekly.doc(uid).delete(),
      _refs.leaderboardMonthly.doc(uid).delete(),
    ];

    try {
      await Future.wait(deleteFutures);
      if (kDebugMode) debugPrint('Deleted all Firestore documents for uid=$uid');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete some Firestore documents: $e');
      return 'Failed to delete cloud data: $e';
    }
    return null;
  }

  /// Deletes the username reservation index document.
  Future<String?> _deleteUsernameIndex() async {
    final usernameLower = playerNameLower;
    if (usernameLower == null || usernameLower.isEmpty) return null;

    try {
      await _refs.usernames.doc(usernameLower).delete();
      if (kDebugMode) debugPrint('Deleted username index: $usernameLower');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete username index: $e');
      return 'Failed to release username: $e';
    }
    return null;
  }

  /// Deletes the Firebase Auth user, handling re-authentication if required.
  Future<String?> _deleteAuthUser(User user, String uid) async {
    try {
      await user.delete();
      if (kDebugMode) debugPrint('Deleted Firebase Auth user: $uid');
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        if (kDebugMode) debugPrint('Failed to delete account: ${e.code} ${e.message}');
        return 'Failed to delete account: ${e.message}';
      }
      return _retryDeleteAfterReauth(uid);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete account: $e');
      return 'Failed to delete account: $e';
    }
  }

  /// Re-authenticates with Google then retries user deletion.
  Future<String?> _retryDeleteAfterReauth(String uid) async {
    if (kDebugMode) debugPrint('Re-authentication required for account deletion');
    final reauthUser = await _auth.reauthenticateWithGoogle();
    if (reauthUser == null) {
      return 'Re-authentication was cancelled. Account deletion cannot continue.';
    }
    try {
      await _auth.currentUser?.delete();
      if (kDebugMode) debugPrint('Deleted Firebase Auth user after re-auth: $uid');
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Failed to delete account after re-auth: ${e.code} ${e.message}');
      return 'Failed to delete account after re-authentication: ${e.message}';
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete account after re-auth: $e');
      return 'Failed to delete account after re-authentication: $e';
    }
  }

  /// Signs out and clears all local session data.
  Future<void> _clearLocalSession() async {
    await _auth.signOut(clearLocalSession: () async {
      final storage = sl<StorageService>();
      await storage.remove('player_name_prompt_completed');
      await storage.remove(StorageKeys.coins);
      await storage.remove(StorageKeys.bestScore);
      await storage.remove(StorageKeys.unlockedCharacters);
      await storage.remove(StorageKeys.selectedCharacter);
      await storage.remove(StorageKeys.hasSeenAppOpenAd);
      await storage.remove(StorageKeys.pendingRewardedCoins);
      await storage.remove(StorageKeys.playerStats);
      await storage.remove(StorageKeys.achievementProgress);
      await storage.remove(StorageKeys.leaderboard);
      await storage.remove(StorageKeys.completedGames);
      await storage.remove(StorageKeys.lastInterstitialGame);
      if (kDebugMode) debugPrint('Cleared local session data');
    });
  }

  /// Resets in-memory state so the app behaves like a fresh install.
  void _resetAfterDeletion(String uid) {
    _player.reset();
    _initializing = false;
    notifyListeners();
    if (kDebugMode) debugPrint('Account deletion complete for uid=$uid');
  }

  /// Notifies listeners that player state has changed (e.g. after a username
  /// update). Exposed so callers outside this package can trigger UI refreshes.
  void refreshPlayerState() {
    notifyListeners();
  }
}
