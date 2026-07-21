import 'dart:convert';

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
import 'package:neon_flap1_game/firebase/player_name_validator.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/services/achievement_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/coin_sync_service.dart';
import 'package:neon_flap1_game/services/leaderboard_service.dart';
import 'package:neon_flap1_game/services/offline_profile_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/settings_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/firebase/player_name_repository.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

/// Single entry point that composes all Firebase sub-services and coordinates
/// the sync between local game state and Firestore.
///
/// The game always works offline: if sign-in fails or a write errors, local
/// SharedPreferences remains authoritative and the cloud simply catches up
/// later. Nothing here should ever throw into the UI.
class FirebaseService extends ChangeNotifier {
  FirebaseService(
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AuthService authService,
    OfflineProfileService offlineProfile,
  )   : _auth = authService,
        _offline = offlineProfile,
        _refs = firestore == null ? null : FirebaseRefs(firestore) {
    final refs = _refs;
    if (refs != null) {
      _player = PlayerService(refs);
      _leaderboard = CloudLeaderboardService(refs);
      _username = PlayerNameService(refs);
    }
    _dailyReward = DailyRewardService(refs);
  }

  final AuthService _auth;
  final OfflineProfileService _offline;
  final FirebaseRefs? _refs;
  PlayerService? _player;
  CloudLeaderboardService? _leaderboard;
  late final DailyRewardService _dailyReward;
  PlayerNameService? _username;
  final PlayerNameValidator _offlineNameValidator = PlayerNameValidator();

  bool _initializing = true;

  bool get initializing => _initializing;
  bool get isCloudAvailable => _refs != null;
  bool get isOfflineGuest => _offline.isGuestSessionActive;
  bool get hasOfflineProfile => _offline.hasOfflineProfile;
  bool get hasCompletedOfflineProfile => _offline.isProfileComplete;
  bool get hasPendingGuestMigration => _offline.hasPendingMigration;
  bool get hasIncompleteOfflineProfile =>
      _offline.hasOfflineProfile && !_offline.isProfileComplete;
  bool get hasActiveIncompleteOfflineProfile =>
      _offline.isSessionActive && !_offline.isProfileComplete;
  bool get isSignedIn => _auth.isSignedIn && !isOfflineGuest;
  String? get uid => isOfflineGuest ? null : _auth.uid;
  String? get error => _auth.error;
  OfflineProgressSnapshot? get offlineSnapshot => _offline.snapshot;

  AuthService get auth => _auth;
  PlayerService get player {
    final service = _player;
    if (service == null) {
      throw StateError('Cloud player service is unavailable.');
    }
    return service;
  }

  CloudLeaderboardService get leaderboard {
    final service = _leaderboard;
    if (service == null) {
      throw StateError('Cloud leaderboard service is unavailable.');
    }
    return service;
  }

  DailyRewardService get dailyReward => _dailyReward;
  PlayerNameService get playerNameService {
    final service = _username;
    if (service == null) {
      throw StateError('Cloud player-name service is unavailable.');
    }
    return service;
  }

  PlayerNameValidator get playerNameValidator =>
      _username?.validator ?? _offlineNameValidator;

  /// The player's display name, falling back to a UID-derived default.
  String get playerName => isOfflineGuest
      ? _offline.playerName ?? 'Player'
      : _player?.username ?? 'Player';
  bool get hasPlayerName =>
      isOfflineGuest ? _offline.hasPlayerName : _player?.hasUsername ?? false;
  String? get playerNameLower => isOfflineGuest
      ? _offline.playerName?.toLowerCase()
      : _player?.profile['usernameLower'] as String?;
  bool get hasDefaultPlayerName =>
      isOfflineGuest ? false : _player?.hasDefaultUsername ?? false;

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
  bool get needsPlayerName => isOfflineGuest
      ? !_offline.isProfileComplete
      : (_player?.profileExisted == false ||
          !hasPlayerName ||
          hasDefaultPlayerName);

  Future<bool> get playerNamePromptCompleted async {
    final storage = sl<StorageService>();
    return storage.getBool(StorageKeys.playerNamePromptCompleted) ?? false;
  }

  Future<void> setPlayerNamePromptCompleted() async {
    final storage = sl<StorageService>();
    await storage.setBool(StorageKeys.playerNamePromptCompleted, true);
  }

  /// Loads the cloud profile for the currently authenticated user.
  ///
  /// The cloud profile is authoritative for every Google account. Device-local
  /// values are never merged into it because they may belong to a different
  /// account that previously used this device. For brand-new accounts,
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
    if (!isCloudAvailable || _player == null) {
      _initializing = false;
      notifyListeners();
      return null;
    }
    final user = await _auth.restoreSession();
    if (user == null) {
      _initializing = false;
      notifyListeners();
      return null;
    }

    final profile = await _player!
        .loadOrCreate(
      user.uid,
      localCoins: localCoins,
      localHighScore: localHighScore,
      avatarId: avatarId,
    )
        .timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        if (kDebugMode) debugPrint('FirebaseService.bootstrap timed out');
        return <String, dynamic>{};
      },
    );

    await _restoreCloudInventory(user.uid);
    await _applyAccountEntitlements();

    final cloudCoins = (profile['coins'] as num?)?.toInt() ?? 0;
    final cloudHigh = (profile['highScore'] as num?)?.toInt() ?? 0;

    // SharedPreferences is device-wide, so taking a local maximum here could
    // leak progress from a previous Google account on the same device.
    final mergedCoins = cloudCoins;
    final mergedHigh = cloudHigh;

    _initializing = false;
    notifyListeners();
    return (
      coins: mergedCoins,
      highScore: mergedHigh,
      playerDocumentExists: profile.isNotEmpty && profile['username'] != null,
    );
  }

  /// Restores the character collection separately from player profile values.
  /// The cloud snapshot remains account-scoped, so no other user's device cache
  /// can appear in the active shop after an account switch.
  Future<void> _restoreCloudInventory(String uid) async {
    final player = _player;
    if (player == null) return;
    final inventory = await player
        .loadInventory(uid)
        .timeout(const Duration(seconds: 6), onTimeout: () => null);
    if (inventory == null) return;
    try {
      await sl<OwnedCharactersService>().restoreFromCloud(
        unlockedIds: inventory.ownedBirds,
        selectedId: inventory.selectedBird,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Cloud inventory restore skipped: $e');
    }
  }

  /// Applies the requested all-character grant after Firebase has verified the
  /// Google identity and [PlayerService] is bound to that account's UID.
  /// No unauthenticated or cross-account Firestore write is ever made.
  Future<void> _applyAccountEntitlements() async {
    if (!AccountEntitlements.unlocksAllCharacters(_auth.currentUser?.email)) {
      return;
    }
    try {
      final owned = sl<OwnedCharactersService>();
      final changed = await owned.grantAllCharacters();
      if (changed) {
        await syncInventory(
          selectedBird: owned.selectedId,
          ownedBirds: owned.allKnownOwnedIds.toList(growable: false),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Account entitlement sync skipped: $e');
    }
  }

  Future<PlayerNameResult> setPlayerName(String name) async {
    if (isOfflineGuest) return setOfflinePlayerName(name);
    final currentUid = uid;
    final username = _username;
    final refs = _refs;
    if (currentUid == null || username == null || refs == null) {
      return PlayerNameResult.error;
    }
    final result = await username.change(profileData(name), name);
    if (result == PlayerNameResult.success) {
      _player?.updateUsername(name);
      // Preserve every existing difficulty row without creating a zero-score
      // entry for a newly named player.
      await _leaderboard?.updateUsername(
        uid: currentUid,
        username: name.trim(),
      );
      refreshPlayerState();
    }
    return result;
  }

  Future<PlayerNameResult> setOfflinePlayerName(String name) async {
    final error = playerNameValidator.validate(name);
    if (error != null) return PlayerNameResult.invalid;
    try {
      await _offline.completeProfile(name);
      await setPlayerNamePromptCompleted();
      refreshPlayerState();
      return PlayerNameResult.success;
    } catch (e) {
      if (kDebugMode) debugPrint('Offline player-name save failed: $e');
      return PlayerNameResult.error;
    }
  }

  Future<OfflineProfileStart> activateOfflineProfile() async {
    final result = await _offline.startSession();
    await _reloadLocalServices();
    _player?.reset();
    _initializing = false;
    notifyListeners();
    return result;
  }

  Future<void> prepareForOnlineSignIn() async {
    if (_offline.hasOfflineProfile &&
        (_offline.isSessionActive || !_offline.hasSnapshot)) {
      await _offline.saveProgressSnapshot();
    }
    if (_offline.hasSnapshot) {
      await _offline.markMigrationInProgress();
    }
    await _offline.useCloudSession();
    await _clearLocalProgressKeys(includeSettings: false);
    await _reloadLocalServices();
    _player?.reset();
    notifyListeners();
  }

  Future<void> keepCloudProgress() async {
    await _offline.useCloudSession();
    notifyListeners();
  }

  Future<void> cancelGoogleMigration() async {
    await _auth.signOut();
    await _offline.startSession();
    await _reloadLocalServices();
    _player?.reset();
    _initializing = false;
    notifyListeners();
  }

  Future<bool> mergeOfflineProgress() async {
    final snapshot = _offline.snapshot;
    if (snapshot == null) {
      await keepCloudProgress();
      return true;
    }

    final refs = _refs;
    final currentUid = uid;
    if (refs == null || currentUid == null) {
      await _offline.markMigrationFailed();
      return false;
    }

    if (_offline.isMigrationCompleteFor(
      cloudUid: currentUid,
      guestId: snapshot.guestId,
    )) {
      await _offline.useCloudSession();
      notifyListeners();
      return true;
    }

    await _offline.markMigrationInProgress();
    final migrationId =
        _offline.migrationId ?? snapshot.guestId ?? 'guest_local_snapshot';
    final coins = sl<CoinService>();
    final storage = sl<StorageService>();
    final settings = sl<SettingsService>().settings;
    final guestDifficultyEntries =
        LeaderboardService.bestByDifficultyFromEncoded(
      snapshot.localLeaderboard,
    );

    var mergedCoins = coins.coins;
    var mergedBest = coins.bestScore;
    var selectedBird = CharactersData.roster.first.id;
    var ownedBirds = <String>{CharactersData.roster.first.id};
    var alreadyCompleted = false;

    try {
      await refs.db.runTransaction((tx) async {
        final playerRef = refs.player(currentUid);
        final inventoryRef = refs.inventory.doc(currentUid);
        final achievementsRef = refs.achievements.doc(currentUid);
        final settingsRef = refs.settings.doc(currentUid);
        final cloudSaveRef = refs.cloudSave.doc(currentUid);
        final dailyRewardsRef = refs.dailyRewards.doc(currentUid);

        final playerDoc = await tx.get(playerRef);
        final inventoryDoc = await tx.get(inventoryRef);
        final achievementsDoc = await tx.get(achievementsRef);

        final cloudProfile = playerDoc.data() ?? const <String, dynamic>{};
        final cloudInventory = inventoryDoc.data() ?? const <String, dynamic>{};
        final migration = cloudProfile['guestMigration'];
        if (migration is Map &&
            migration['id'] == migrationId &&
            migration['status'] ==
                GuestMigrationStatus.completed.storageValue) {
          alreadyCompleted = true;
          mergedCoins = (cloudProfile['coins'] as num?)?.toInt() ?? coins.coins;
          mergedBest =
              (cloudProfile['highScore'] as num?)?.toInt() ?? coins.bestScore;
          ownedBirds = _readStringSet(
            cloudInventory['ownedBirds'],
            fallback: snapshot.unlockedCharacters,
          )..addAll(snapshot.retiredUnlockedCharacters);
          selectedBird = _chooseSelectedBird(
            localSelected: snapshot.selectedCharacter,
            cloudSelected: cloudInventory['selectedBird'] as String?,
            owned: ownedBirds,
          );
          return;
        }

        final cloudCoins = (cloudProfile['coins'] as num?)?.toInt() ?? 0;
        final cloudBest = (cloudProfile['highScore'] as num?)?.toInt() ?? 0;
        mergedCoins = cloudCoins + snapshot.coins;
        mergedBest =
            cloudBest > snapshot.bestScore ? cloudBest : snapshot.bestScore;
        ownedBirds = _readStringSet(
          cloudInventory['ownedBirds'],
          fallback: const <String>[],
        )
          ..addAll(snapshot.unlockedCharacters)
          ..addAll(snapshot.retiredUnlockedCharacters)
          ..add(CharactersData.roster.first.id);
        selectedBird = _chooseSelectedBird(
          localSelected: snapshot.selectedCharacter,
          cloudSelected: cloudInventory['selectedBird'] as String?,
          owned: ownedBirds,
        );

        tx.set(
          playerRef,
          {
            'coins': mergedCoins,
            'highScore': mergedBest,
            'bestDistance': mergedBest,
            'avatar': selectedBird,
            'guestMigration': {
              'id': migrationId,
              'status': GuestMigrationStatus.completed.storageValue,
              'completedAt': FieldValue.serverTimestamp(),
              'guestCoins': snapshot.coins,
              'guestHighScore': snapshot.bestScore,
            },
            'lastLogin': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        tx.set(
          cloudSaveRef,
          {
            'coins': mergedCoins,
            'highScore': mergedBest,
            'checkpoint': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        tx.set(
          inventoryRef,
          {
            'selectedBird': selectedBird,
            'ownedBirds': ownedBirds.toList()..sort(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        final achievements = _mergeAchievementProgress(
          snapshot.achievementProgress,
          achievementsDoc.data(),
        );
        if (achievements.isNotEmpty) {
          tx.set(
            achievementsRef,
            {
              ...achievements,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        tx.set(
          settingsRef,
          {
            'music': settings.musicVolume > 0,
            'sound': settings.sfxVolume > 0,
            'vibration': settings.vibration,
            'musicVolume': settings.musicVolume,
            'sfxVolume': settings.sfxVolume,
            'menuTrackId': settings.selectedMenuTrackId,
            'gameplayTrackId': settings.selectedGameplayTrackId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        final daily = _dailyRewardMerge(snapshot);
        if (daily.isNotEmpty) {
          tx.set(
            dailyRewardsRef,
            {
              ...daily,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Guest migration failed: $e');
      await _offline.markMigrationFailed();
      notifyListeners();
      return false;
    }

    await coins.setFromCloud(mergedCoins);
    await coins.setBestScoreFromCloud(mergedBest);
    await storage.setStringList(
      StorageKeys.unlockedCharacters,
      ownedBirds.where(CharactersData.activeIds.contains).toList()..sort(),
    );
    await storage.setStringList(
      StorageKeys.retiredUnlockedCharacters,
      ownedBirds.where((id) => !CharactersData.activeIds.contains(id)).toList()
        ..sort(),
    );
    await storage.setString(StorageKeys.selectedCharacter, selectedBird);
    if (snapshot.playerStats != null) {
      await storage.setString(StorageKeys.playerStats, snapshot.playerStats!);
    }
    await storage.setStringList(
      StorageKeys.achievementProgress,
      snapshot.achievementProgress,
    );
    await storage.setStringList(
      StorageKeys.leaderboard,
      snapshot.localLeaderboard,
    );
    await _setOptionalInt(
        storage, StorageKeys.guestEasyBest, snapshot.guestEasyBest);
    await _setOptionalInt(
        storage, StorageKeys.guestNormalBest, snapshot.guestNormalBest);
    await _setOptionalInt(
        storage, StorageKeys.guestHardBest, snapshot.guestHardBest);
    await _setOptionalInt(
      storage,
      StorageKeys.dailyRewardLastClaim,
      snapshot.dailyRewardLastClaim,
    );
    await _setOptionalInt(
      storage,
      StorageKeys.dailyRewardClaimedDay,
      snapshot.dailyRewardClaimedDay,
    );
    await _setOptionalInt(
      storage,
      StorageKeys.dailyRewardClaimedStreak,
      snapshot.dailyRewardClaimedStreak,
    );

    await _reloadLocalServices();
    await _player?.loadOrCreate(
      currentUid,
      localCoins: mergedCoins,
      localHighScore: mergedBest,
      avatarId: selectedBird,
    );
    // Existing guest rows carry an explicit difficulty, so each can safely
    // merge by max with its matching cloud board. No old global score is ever
    // guessed into a difficulty.
    for (final entry in guestDifficultyEntries.values) {
      await _leaderboard?.submitScore(
        uid: currentUid,
        username: playerName,
        score: entry.score,
        difficulty: entry.difficulty,
        selectedCharacterId:
            entry.characterId.isEmpty ? selectedBird : entry.characterId,
      );
    }
    await _offline.markMigrationCompleted(cloudUid: currentUid);
    if (alreadyCompleted && kDebugMode) {
      debugPrint('Guest migration already completed for $migrationId.');
    }
    notifyListeners();
    return true;
  }

  Set<String> _readStringSet(
    Object? value, {
    required List<String> fallback,
  }) {
    final items = <String>{CharactersData.roster.first.id, ...fallback};
    if (value is Iterable) {
      items.addAll(value.whereType<String>());
    }
    return items;
  }

  String _chooseSelectedBird({
    required String localSelected,
    required String? cloudSelected,
    required Set<String> owned,
  }) {
    final localActive = CharactersData.mapToActiveId(localSelected);
    if (owned.contains(localSelected) || owned.contains(localActive)) {
      return localActive;
    }
    if (cloudSelected != null) {
      final cloudActive = CharactersData.mapToActiveId(cloudSelected);
      if (owned.contains(cloudSelected) || owned.contains(cloudActive)) {
        return cloudActive;
      }
    }
    return CharactersData.roster.first.id;
  }

  Map<String, bool> _mergeAchievementProgress(
    List<String> guestProgress,
    Map<String, dynamic>? cloudProgress,
  ) {
    final merged = <String, bool>{};
    if (cloudProgress != null) {
      for (final entry in cloudProgress.entries) {
        if (entry.value is bool && entry.value == true) {
          merged[entry.key] = true;
        }
      }
    }
    for (final encoded in guestProgress) {
      try {
        final map = jsonDecode(encoded) as Map<String, dynamic>;
        final id = map['achievementId'] as String?;
        final claimed = map['claimed'] as bool? ?? false;
        if (id != null && id.isNotEmpty && claimed) {
          merged[id] = true;
        }
      } catch (_) {
        // Ignore corrupt local achievement rows.
      }
    }
    return merged;
  }

  Map<String, Object?> _dailyRewardMerge(OfflineProgressSnapshot snapshot) {
    final lastClaim = snapshot.dailyRewardLastClaim;
    final day = snapshot.dailyRewardClaimedDay;
    final streak = snapshot.dailyRewardClaimedStreak;
    if (lastClaim == null && day == null && streak == null) {
      return const <String, Object?>{};
    }
    return {
      if (lastClaim != null)
        'lastClaim': Timestamp.fromMillisecondsSinceEpoch(lastClaim),
      if (day != null) 'day': day,
      if (streak != null) 'streak': streak,
    };
  }

  Future<void> _setOptionalInt(
    StorageService storage,
    String key,
    int? value,
  ) {
    if (value == null) return storage.remove(key);
    return storage.setInt(key, value);
  }

  Future<void> leaveOfflineProfile() async {
    await _offline.leaveSession();
    _initializing = false;
    notifyListeners();
  }

  Future<void> deleteOfflineProfile() async {
    await _clearLocalProgressKeys(includeSettings: true);
    await _offline.deleteProfileOnly();
    await _reloadLocalServices();
    _player?.reset();
    _initializing = false;
    notifyListeners();
  }

  Future<void> syncCoins(int coins) {
    if (isOfflineGuest) return Future.value();
    return _player?.syncCoins(coins) ?? Future.value();
  }

  Future<void> syncInventory({
    required String selectedBird,
    required List<String> ownedBirds,
  }) {
    if (isOfflineGuest) return Future.value();
    return _player?.syncInventory(
          selectedBird: selectedBird,
          ownedBirds: ownedBirds,
        ) ??
        Future.value();
  }

  Future<void> syncSettings({
    required bool music,
    required bool sound,
    required bool vibration,
  }) {
    if (isOfflineGuest) return Future.value();
    final settings = sl<SettingsService>().settings;
    return _player?.syncSettings(
          music: music,
          sound: sound,
          vibration: vibration,
          musicVolume: settings.musicVolume,
          sfxVolume: settings.sfxVolume,
          menuTrackId: settings.selectedMenuTrackId,
          gameplayTrackId: settings.selectedGameplayTrackId,
        ) ??
        Future.value();
  }

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
    if (isOfflineGuest) return;
    final currentUid = uid;
    final player = _player;
    final leaderboard = _leaderboard;
    if (currentUid == null || player == null || leaderboard == null) return;
    await player.recordRun(
      score: score,
      coinsEarned: coinsEarned,
      difficulty: mode.name,
      avatarId: avatarId,
    );
    await player.syncHighScore(bestScore);
    // Coin balance is not written here — [CoinSyncService] is the sole
    // runtime writer, triggered by every [CoinService.addCoins] call.
    await player.syncCloudSave(coins: totalCoins, highScore: bestScore);
    if (achievementsUnlocked.isNotEmpty) {
      await player.syncAchievements(achievementsUnlocked);
    }
    await leaderboard.submitScore(
      uid: currentUid,
      username: playerName,
      score: score,
      difficulty: mode,
      selectedCharacterId: avatarId,
    );
  }

  /// Claims the daily reward, returning the coins granted (0 if unavailable).
  Future<int> claimDailyReward() async {
    if (isOfflineGuest) return _dailyReward.claimLocal();
    final currentUid = uid;
    if (currentUid == null) return 0;
    return _dailyReward.claim(currentUid);
  }

  /// Signs out of Google/Firebase and clears all account-scoped local state.
  /// Services remain registered for the login screen, but they no longer keep
  /// the previous account's progress in memory.
  Future<void> signOut() async {
    await _clearLocalSession();
    _player?.reset();
    _initializing = false;
    notifyListeners();
  }

  Future<DailyRewardStatus> dailyRewardStatus() async {
    if (isOfflineGuest) return _dailyReward.statusLocal();
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
    final refs = _refs;
    if (refs == null) return 'Cloud services are unavailable right now.';
    final deleteFutures = <Future>[
      refs.player(uid).delete(),
      refs.cloudSave.doc(uid).delete(),
      refs.inventory.doc(uid).delete(),
      refs.achievements.doc(uid).delete(),
      refs.dailyRewards.doc(uid).delete(),
      refs.settings.doc(uid).delete(),
      refs.leaderboard.doc(uid).delete(),
      refs.leaderboardWeekly.doc(uid).delete(),
      refs.leaderboardMonthly.doc(uid).delete(),
    ];

    try {
      await Future.wait(deleteFutures);
      if (kDebugMode) {
        debugPrint('Deleted all Firestore documents for uid=$uid');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete some Firestore documents: $e');
      }
      return 'Failed to delete cloud data: $e';
    }
    return null;
  }

  /// Deletes the username reservation index document.
  Future<String?> _deleteUsernameIndex() async {
    final usernameLower = playerNameLower;
    if (usernameLower == null || usernameLower.isEmpty) return null;

    try {
      await _refs?.usernames.doc(usernameLower).delete();
      if (kDebugMode) {
        debugPrint('Deleted username index: $usernameLower');
      }
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
        if (kDebugMode) {
          debugPrint('Failed to delete account: ${e.code} ${e.message}');
        }
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
    if (kDebugMode) {
      debugPrint('Re-authentication required for account deletion');
    }
    final reauthUser = await _auth.reauthenticateWithGoogle();
    if (reauthUser == null) {
      return 'Re-authentication was cancelled. Account deletion cannot continue.';
    }
    try {
      await _auth.currentUser?.delete();
      if (kDebugMode) {
        debugPrint('Deleted Firebase Auth user after re-auth: $uid');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
            'Failed to delete account after re-auth: ${e.code} ${e.message}');
      }
      return 'Failed to delete account after re-authentication: ${e.message}';
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete account after re-auth: $e');
      return 'Failed to delete account after re-authentication: $e';
    }
  }

  /// Signs out and clears all local session data.
  Future<void> _clearLocalSession() async {
    try {
      await sl<CoinSyncService>().resetForAccountChange();
    } catch (_) {
      // The sync service may not be registered after an early-startup error.
    }
    await _auth.signOut(clearLocalSession: () async {
      final storage = sl<StorageService>();
      await storage.remove(StorageKeys.playerNamePromptCompleted);
      await _clearLocalProgressKeys(includeSettings: false);
      if (kDebugMode) debugPrint('Cleared local session data');
    });
    _resetInMemoryProgress();
  }

  Future<void> _clearLocalProgressKeys({required bool includeSettings}) async {
    final storage = sl<StorageService>();
    await storage.remove(StorageKeys.coins);
    await storage.remove(StorageKeys.bestScore);
    await storage.remove(StorageKeys.unlockedCharacters);
    await storage.remove(StorageKeys.retiredUnlockedCharacters);
    await storage.remove(StorageKeys.characterCatalogVersion);
    await storage.remove(StorageKeys.selectedCharacter);
    await storage.remove(StorageKeys.hasSeenAppOpenAd);
    await storage.remove(StorageKeys.pendingRewardedCoins);
    await storage.remove(StorageKeys.playerStats);
    await storage.remove(StorageKeys.achievementProgress);
    await storage.remove(StorageKeys.leaderboard);
    await storage.remove(StorageKeys.guestEasyBest);
    await storage.remove(StorageKeys.guestNormalBest);
    await storage.remove(StorageKeys.guestHardBest);
    await storage.remove(StorageKeys.completedGames);
    await storage.remove(StorageKeys.lastInterstitialGame);
    await storage.remove(StorageKeys.dailyRewardLastClaim);
    await storage.remove(StorageKeys.dailyRewardClaimedDay);
    await storage.remove(StorageKeys.dailyRewardClaimedStreak);
    await storage.remove(StorageKeys.dailyRewardPendingOffline);
    await storage.remove(StorageKeys.pendingCloudCoins);
    await storage.remove(StorageKeys.coinSyncPending);
    if (includeSettings) await storage.remove(StorageKeys.settings);
  }

  Future<void> _reloadLocalServices() async {
    try {
      await sl<CoinService>().load();
    } catch (_) {}
    try {
      await sl<OwnedCharactersService>().load();
    } catch (_) {}
    try {
      await sl<AchievementService>().load();
    } catch (_) {}
    try {
      await sl<LeaderboardService>().load();
    } catch (_) {}
    try {
      await sl<SettingsService>().load();
    } catch (_) {}
  }

  void _resetInMemoryProgress() {
    try {
      sl<CoinService>().reset();
    } catch (_) {}
    try {
      sl<OwnedCharactersService>().reset();
    } catch (_) {}
    try {
      sl<AchievementService>().reset();
    } catch (_) {}
    try {
      sl<LeaderboardService>().reset();
    } catch (_) {}
  }

  /// Resets in-memory state so the app behaves like a fresh install.
  void _resetAfterDeletion(String uid) {
    _player?.reset();
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
