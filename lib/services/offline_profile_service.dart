import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

enum OfflineProfileStart {
  needsPlayerName,
  ready,
}

enum GuestMigrationStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed'),
  failed('failed');

  const GuestMigrationStatus(this.storageValue);
  final String storageValue;

  static GuestMigrationStatus fromStorage(String? value) {
    for (final status in values) {
      if (status.storageValue == value) return status;
    }
    return GuestMigrationStatus.notStarted;
  }
}

@immutable
class OfflineProgressSnapshot {
  const OfflineProgressSnapshot({
    required this.guestId,
    required this.playerName,
    required this.coins,
    required this.bestScore,
    required this.unlockedCharacters,
    required this.retiredUnlockedCharacters,
    required this.selectedCharacter,
    required this.settings,
    required this.playerStats,
    required this.achievementProgress,
    required this.localLeaderboard,
    required this.guestEasyBest,
    required this.guestNormalBest,
    required this.guestHardBest,
    required this.completedGames,
    required this.dailyRewardLastClaim,
    required this.dailyRewardClaimedDay,
    required this.dailyRewardClaimedStreak,
  });

  final String? guestId;
  final String? playerName;
  final int coins;
  final int bestScore;
  final List<String> unlockedCharacters;
  final List<String> retiredUnlockedCharacters;
  final String selectedCharacter;
  final String? settings;
  final String? playerStats;
  final List<String> achievementProgress;
  final List<String> localLeaderboard;
  final int? guestEasyBest;
  final int? guestNormalBest;
  final int? guestHardBest;
  final int? completedGames;
  final int? dailyRewardLastClaim;
  final int? dailyRewardClaimedDay;
  final int? dailyRewardClaimedStreak;

  Map<String, dynamic> toJson() => {
        'guestId': guestId,
        'playerName': playerName,
        'coins': coins,
        'bestScore': bestScore,
        'unlockedCharacters': unlockedCharacters,
        'retiredUnlockedCharacters': retiredUnlockedCharacters,
        'selectedCharacter': selectedCharacter,
        'settings': settings,
        'playerStats': playerStats,
        'achievementProgress': achievementProgress,
        'localLeaderboard': localLeaderboard,
        'guestEasyBest': guestEasyBest,
        'guestNormalBest': guestNormalBest,
        'guestHardBest': guestHardBest,
        'completedGames': completedGames,
        'dailyRewardLastClaim': dailyRewardLastClaim,
        'dailyRewardClaimedDay': dailyRewardClaimedDay,
        'dailyRewardClaimedStreak': dailyRewardClaimedStreak,
      };

  factory OfflineProgressSnapshot.fromJson(Map<String, dynamic> json) {
    List<String> readList(String key) =>
        (json[key] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList();

    return OfflineProgressSnapshot(
      guestId: json['guestId'] as String?,
      playerName: json['playerName'] as String?,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      unlockedCharacters: readList('unlockedCharacters'),
      retiredUnlockedCharacters: readList('retiredUnlockedCharacters'),
      selectedCharacter: json['selectedCharacter'] as String? ??
          CharactersData.roster.first.id,
      settings: json['settings'] as String?,
      playerStats: json['playerStats'] as String?,
      achievementProgress: readList('achievementProgress'),
      localLeaderboard: readList('localLeaderboard'),
      guestEasyBest: (json['guestEasyBest'] as num?)?.toInt(),
      guestNormalBest: (json['guestNormalBest'] as num?)?.toInt(),
      guestHardBest: (json['guestHardBest'] as num?)?.toInt(),
      completedGames: (json['completedGames'] as num?)?.toInt(),
      dailyRewardLastClaim: (json['dailyRewardLastClaim'] as num?)?.toInt(),
      dailyRewardClaimedDay: (json['dailyRewardClaimedDay'] as num?)?.toInt(),
      dailyRewardClaimedStreak:
          (json['dailyRewardClaimedStreak'] as num?)?.toInt(),
    );
  }
}

/// Owns the local-only guest identity and an explicit backup of guest progress.
///
/// The game state itself continues to live in the existing SharedPreferences
/// services. The snapshot lets a guest sign in with Google without silently
/// losing local progress when cloud values are loaded into those shared keys.
class OfflineProfileService extends ChangeNotifier {
  OfflineProfileService(this._storage);

  final StorageService _storage;
  final Random _random = Random();

  String? _guestId;
  String? _playerName;
  bool _hasOfflineProfile = false;
  bool _profileComplete = false;
  bool _isOfflinePlayer = false;
  OfflineProgressSnapshot? _snapshot;
  String? _migrationId;
  GuestMigrationStatus _migrationStatus = GuestMigrationStatus.notStarted;
  int? _migrationCompletedAt;
  String? _migrationCloudUid;

  String? get guestId => _guestId;
  String? get playerName => _playerName;
  bool get hasOfflineProfile => _hasOfflineProfile;
  bool get isProfileComplete => _profileComplete && hasPlayerName;
  bool get hasIncompleteOfflineProfile =>
      _hasOfflineProfile && !isProfileComplete;
  bool get hasPlayerName => (_playerName?.trim().isNotEmpty ?? false);
  bool get isSessionActive => _isOfflinePlayer;
  bool get isGuestSessionActive => _isOfflinePlayer && isProfileComplete;
  bool get hasSnapshot => _snapshot != null;
  OfflineProgressSnapshot? get snapshot => _snapshot;
  String? get migrationId => _migrationId;
  GuestMigrationStatus get migrationStatus => _migrationStatus;
  int? get migrationCompletedAt => _migrationCompletedAt;
  String? get migrationCloudUid => _migrationCloudUid;
  bool get hasPendingMigration =>
      _snapshot != null && _migrationStatus != GuestMigrationStatus.completed;

  Future<void> load() async {
    _guestId = _storage.getString(StorageKeys.offlineGuestId);
    _playerName = _storage.getString(StorageKeys.offlinePlayerName);
    _hasOfflineProfile =
        _storage.getBool(StorageKeys.hasOfflineProfile) ?? false;
    _profileComplete =
        _storage.getBool(StorageKeys.offlineProfileComplete) ?? false;
    _isOfflinePlayer = _storage.getBool(StorageKeys.isOfflinePlayer) ?? false;
    _snapshot = _readSnapshot();
    _migrationId = _storage.getString(StorageKeys.guestMigrationId);
    _migrationStatus = GuestMigrationStatus.fromStorage(
      _storage.getString(StorageKeys.guestMigrationStatus),
    );
    _migrationCompletedAt =
        _storage.getInt(StorageKeys.guestMigrationCompletedAt);
    _migrationCloudUid = _storage.getString(StorageKeys.guestMigrationCloudUid);

    if (_hasOfflineProfile && _guestId == null) {
      _guestId = _createGuestId();
      await _storage.setString(StorageKeys.offlineGuestId, _guestId!);
    }
    if (_profileComplete && !hasPlayerName) {
      _profileComplete = false;
      await _storage.setBool(StorageKeys.offlineProfileComplete, false);
    }
    if (_isOfflinePlayer && !_hasOfflineProfile) {
      _isOfflinePlayer = false;
      await _storage.setBool(StorageKeys.isOfflinePlayer, false);
    }
    if (_migrationStatus == GuestMigrationStatus.completed &&
        _guestId != null &&
        _guestId == _migrationId) {
      await _deactivateProfileKeepSnapshot();
    }
    notifyListeners();
  }

  Future<OfflineProfileStart> startSession() async {
    await _ensureGuestId();
    _hasOfflineProfile = true;
    _isOfflinePlayer = true;
    await _storage.setBool(StorageKeys.hasOfflineProfile, true);
    await _storage.setBool(StorageKeys.isOfflinePlayer, true);
    await _touchLastPlayed();

    if (isProfileComplete) {
      await restoreProgressSnapshot();
      notifyListeners();
      return OfflineProfileStart.ready;
    }

    _profileComplete = false;
    await _storage.setBool(StorageKeys.offlineProfileComplete, false);
    notifyListeners();
    return OfflineProfileStart.needsPlayerName;
  }

  Future<void> completeProfile(String playerName) async {
    final clean = playerName.trim();
    if (clean.isEmpty) return;
    await _ensureGuestId();
    _playerName = clean;
    _hasOfflineProfile = true;
    _profileComplete = true;
    _isOfflinePlayer = true;
    await _storage.setString(StorageKeys.offlinePlayerName, clean);
    await _storage.setBool(StorageKeys.hasOfflineProfile, true);
    await _storage.setBool(StorageKeys.offlineProfileComplete, true);
    await _storage.setBool(StorageKeys.isOfflinePlayer, true);
    await _touchLastPlayed();
    notifyListeners();
  }

  Future<void> leaveSession() async {
    _isOfflinePlayer = false;
    await _storage.setBool(StorageKeys.isOfflinePlayer, false);
    await saveProgressSnapshot();
    notifyListeners();
  }

  Future<void> useCloudSession() async {
    _isOfflinePlayer = false;
    await _storage.setBool(StorageKeys.isOfflinePlayer, false);
    notifyListeners();
  }

  Future<void> markMigrationInProgress() async {
    if (_snapshot == null || (_hasOfflineProfile && _isOfflinePlayer)) {
      await saveProgressSnapshot();
    }
    _migrationId = _snapshot?.guestId ?? _guestId ?? _migrationId;
    if (_migrationId == null || _migrationId!.isEmpty) {
      await _ensureGuestId();
      _migrationId = _guestId;
    }
    _migrationStatus = GuestMigrationStatus.inProgress;
    await _storage.setString(StorageKeys.guestMigrationId, _migrationId!);
    await _storage.setString(
      StorageKeys.guestMigrationStatus,
      _migrationStatus.storageValue,
    );
    notifyListeners();
  }

  Future<void> markMigrationFailed() async {
    if (_migrationId == null) {
      _migrationId = _snapshot?.guestId ?? _guestId;
      if (_migrationId != null) {
        await _storage.setString(StorageKeys.guestMigrationId, _migrationId!);
      }
    }
    _migrationStatus = GuestMigrationStatus.failed;
    await _storage.setString(
      StorageKeys.guestMigrationStatus,
      _migrationStatus.storageValue,
    );
    notifyListeners();
  }

  Future<void> markMigrationCompleted({required String cloudUid}) async {
    _migrationId = _snapshot?.guestId ?? _guestId ?? _migrationId;
    if (_migrationId != null) {
      await _storage.setString(StorageKeys.guestMigrationId, _migrationId!);
    }
    _migrationStatus = GuestMigrationStatus.completed;
    _migrationCompletedAt = DateTime.now().millisecondsSinceEpoch;
    _migrationCloudUid = cloudUid;
    await _storage.setString(
      StorageKeys.guestMigrationStatus,
      _migrationStatus.storageValue,
    );
    await _storage.setInt(
      StorageKeys.guestMigrationCompletedAt,
      _migrationCompletedAt!,
    );
    await _storage.setString(StorageKeys.guestMigrationCloudUid, cloudUid);
    await _deactivateProfileKeepSnapshot();
    notifyListeners();
  }

  bool isMigrationCompleteFor({required String cloudUid, String? guestId}) {
    if (_migrationStatus != GuestMigrationStatus.completed) return false;
    if (_migrationCloudUid != cloudUid) return false;
    final id = guestId ?? _migrationId;
    return id != null && id == _migrationId;
  }

  Future<void> saveProgressSnapshot() async {
    if (!_hasOfflineProfile) return;
    final snapshot = OfflineProgressSnapshot(
      guestId: _guestId,
      playerName: _playerName,
      coins: _storage.getInt(StorageKeys.coins) ?? 0,
      bestScore: _storage.getInt(StorageKeys.bestScore) ?? 0,
      unlockedCharacters:
          _storage.getStringList(StorageKeys.unlockedCharacters) ??
              const <String>[],
      retiredUnlockedCharacters:
          _storage.getStringList(StorageKeys.retiredUnlockedCharacters) ??
              const <String>[],
      selectedCharacter: _storage.getString(StorageKeys.selectedCharacter) ??
          CharactersData.roster.first.id,
      settings: _storage.getString(StorageKeys.settings),
      playerStats: _storage.getString(StorageKeys.playerStats),
      achievementProgress:
          _storage.getStringList(StorageKeys.achievementProgress) ??
              const <String>[],
      localLeaderboard:
          _storage.getStringList(StorageKeys.leaderboard) ?? const <String>[],
      guestEasyBest: _storage.getInt(StorageKeys.guestEasyBest),
      guestNormalBest: _storage.getInt(StorageKeys.guestNormalBest),
      guestHardBest: _storage.getInt(StorageKeys.guestHardBest),
      completedGames: _storage.getInt(StorageKeys.completedGames),
      dailyRewardLastClaim: _storage.getInt(StorageKeys.dailyRewardLastClaim),
      dailyRewardClaimedDay: _storage.getInt(StorageKeys.dailyRewardClaimedDay),
      dailyRewardClaimedStreak:
          _storage.getInt(StorageKeys.dailyRewardClaimedStreak),
    );
    _snapshot = snapshot;
    await _storage.setString(
      StorageKeys.offlineProfileSnapshot,
      jsonEncode(snapshot.toJson()),
    );
  }

  Future<void> restoreProgressSnapshot() async {
    final snapshot = _snapshot ?? _readSnapshot();
    if (snapshot == null) return;
    _snapshot = snapshot;
    await _storage.setInt(StorageKeys.coins, snapshot.coins);
    await _storage.setInt(StorageKeys.bestScore, snapshot.bestScore);
    await _storage.setStringList(
      StorageKeys.unlockedCharacters,
      snapshot.unlockedCharacters,
    );
    await _storage.setStringList(
      StorageKeys.retiredUnlockedCharacters,
      snapshot.retiredUnlockedCharacters,
    );
    await _storage.setString(
      StorageKeys.selectedCharacter,
      snapshot.selectedCharacter,
    );
    await _setOptionalString(StorageKeys.settings, snapshot.settings);
    await _setOptionalString(StorageKeys.playerStats, snapshot.playerStats);
    await _storage.setStringList(
      StorageKeys.achievementProgress,
      snapshot.achievementProgress,
    );
    await _storage.setStringList(
      StorageKeys.leaderboard,
      snapshot.localLeaderboard,
    );
    await _setOptionalInt(StorageKeys.guestEasyBest, snapshot.guestEasyBest);
    await _setOptionalInt(
        StorageKeys.guestNormalBest, snapshot.guestNormalBest);
    await _setOptionalInt(StorageKeys.guestHardBest, snapshot.guestHardBest);
    await _setOptionalInt(StorageKeys.completedGames, snapshot.completedGames);
    await _setOptionalInt(
      StorageKeys.dailyRewardLastClaim,
      snapshot.dailyRewardLastClaim,
    );
    await _setOptionalInt(
      StorageKeys.dailyRewardClaimedDay,
      snapshot.dailyRewardClaimedDay,
    );
    await _setOptionalInt(
      StorageKeys.dailyRewardClaimedStreak,
      snapshot.dailyRewardClaimedStreak,
    );
    await _storage.setBool(StorageKeys.dailyRewardPendingOffline, false);
  }

  Future<void> deleteProfileOnly() async {
    _guestId = null;
    _playerName = null;
    _hasOfflineProfile = false;
    _profileComplete = false;
    _isOfflinePlayer = false;
    _snapshot = null;
    await _storage.remove(StorageKeys.offlineGuestId);
    await _storage.remove(StorageKeys.offlinePlayerName);
    await _storage.remove(StorageKeys.hasOfflineProfile);
    await _storage.remove(StorageKeys.offlineProfileComplete);
    await _storage.remove(StorageKeys.isOfflinePlayer);
    await _storage.remove(StorageKeys.offlineProfileCreatedAt);
    await _storage.remove(StorageKeys.offlineProfileLastPlayed);
    await _storage.remove(StorageKeys.offlineProfileSnapshot);
    await _storage.remove(StorageKeys.guestMigrationId);
    await _storage.remove(StorageKeys.guestMigrationStatus);
    await _storage.remove(StorageKeys.guestMigrationCompletedAt);
    await _storage.remove(StorageKeys.guestMigrationCloudUid);
    _migrationId = null;
    _migrationStatus = GuestMigrationStatus.notStarted;
    _migrationCompletedAt = null;
    _migrationCloudUid = null;
    notifyListeners();
  }

  Future<void> _deactivateProfileKeepSnapshot() async {
    _guestId = null;
    _playerName = null;
    _hasOfflineProfile = false;
    _profileComplete = false;
    _isOfflinePlayer = false;
    await _storage.remove(StorageKeys.offlineGuestId);
    await _storage.remove(StorageKeys.offlinePlayerName);
    await _storage.remove(StorageKeys.hasOfflineProfile);
    await _storage.remove(StorageKeys.offlineProfileComplete);
    await _storage.remove(StorageKeys.isOfflinePlayer);
    await _storage.remove(StorageKeys.offlineProfileCreatedAt);
    await _storage.remove(StorageKeys.offlineProfileLastPlayed);
  }

  Future<void> _ensureGuestId() async {
    if (_guestId != null && _guestId!.isNotEmpty) return;
    _guestId = _createGuestId();
    await _storage.setString(StorageKeys.offlineGuestId, _guestId!);
    await _storage.setInt(
      StorageKeys.offlineProfileCreatedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  String _createGuestId() {
    final time = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final nonce = _random.nextInt(1 << 32).toRadixString(36);
    return 'guest_${time}_$nonce';
  }

  OfflineProgressSnapshot? _readSnapshot() {
    final raw = _storage.getString(StorageKeys.offlineProfileSnapshot);
    if (raw == null || raw.isEmpty) return null;
    try {
      return OfflineProgressSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Offline profile snapshot ignored: $e');
      return null;
    }
  }

  Future<void> _touchLastPlayed() async {
    await _storage.setInt(
      StorageKeys.offlineProfileLastPlayed,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _setOptionalInt(String key, int? value) {
    if (value == null) return _storage.remove(key);
    return _storage.setInt(key, value);
  }

  Future<void> _setOptionalString(String key, String? value) {
    if (value == null) return _storage.remove(key);
    return _storage.setString(key, value);
  }
}
