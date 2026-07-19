import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

/// Minimal fake storage backed by an in-memory map.
class FakeStorageService extends StorageService {
  FakeStorageService() : super(FakeSharedPreferences());
}

/// A fake SharedPreferences implementation.
class FakeSharedPreferences implements SharedPreferences {
  final Map<String, dynamic> _data = {};

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Set<String> getKeys() => _data.keys.toSet();

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<bool> reload() async => true;

  @override
  Object? get(String key) => _data[key];
}

// ---------------------------------------------------------------------------
// CoinService / OwnedCharactersService
// ---------------------------------------------------------------------------

/// A fake [CoinService] that does nothing on load.
class FakeCoinService extends CoinService {
  FakeCoinService() : super(FakeStorageService());

  @override
  Future<void> load() async {}
}

/// A fake [OwnedCharactersService] that does nothing on load.
class FakeOwnedCharactersService extends OwnedCharactersService {
  FakeOwnedCharactersService()
      : super(FakeStorageService(), FakeCoinService());

  @override
  Future<void> load() async {}
}

// ---------------------------------------------------------------------------
// PlayerNameService (fake, no Firestore)
// ---------------------------------------------------------------------------

/// Result of a player-name claim attempt (mirrors the real enum).
enum FakePlayerNameResult { success, invalid, taken, error }

/// A fake [PlayerNameService] that works without Firestore.
class FakePlayerNameService {
  FakePlayerNameService({
    this.claimResult = FakePlayerNameResult.success,
  });

  /// The result that [claim] will return.
  FakePlayerNameResult claimResult;

  /// Whether [claim] was called.
  bool claimCalled = false;

  /// The last value passed to [claim].
  String? lastClaimedName;

  final _validator = FakePlayerNameValidatorForTests();

  FakePlayerNameValidatorForTests get validator => _validator;

  String? validateFormat(String value) => _validator.validate(value);

  String toLookupKey(String value) => value.trim().toLowerCase();

  Future<FakePlayerNameResult> claim(dynamic profile, String value) async {
    claimCalled = true;
    lastClaimedName = value;
    return claimResult;
  }
}

/// Minimal validator that mirrors the real PlayerNameValidator rules.
class FakePlayerNameValidatorForTests {
  static const int minLength = 4;
  static const int maxLength = 16;

  final Set<String> blockedWords = {
    'admin', 'root', 'moderator', 'support', 'official',
    'fuck', 'shit', 'bitch', 'nigger', 'nazi', 'hitler',
  };

  String? validate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 'Enter a player name';
    if (raw.length < minLength) return 'Use at least $minLength characters';
    if (raw.length > maxLength) return 'Max $maxLength characters';
    if (raw.contains(RegExp(r'\s'))) return 'No spaces allowed';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(raw)) {
      return 'Letters, numbers and _ only';
    }
    final normalized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final word in blockedWords) {
      final clean = word.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (clean.isNotEmpty && normalized.contains(clean)) {
        return 'This player name is not allowed';
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// AuthService (fake, no Google/Firebase)
// ---------------------------------------------------------------------------

/// A controllable fake [AuthService] for tests.
class FakeAuthService extends ChangeNotifier {
  FakeAuthService({String? initialUid})
      : _uid = initialUid,
        _isSignedIn = initialUid != null;

  String? _uid;
  String? _error;
  bool _isSignedIn;

  /// Controls what [signInWithGoogle] returns.
  bool signInShouldSucceed = true;

  /// Whether [signInWithGoogle] was called.
  bool signInCalled = false;

  /// Whether [signOut] was called.
  bool signOutCalled = false;

  /// Whether [restoreSession] was called.
  bool restoreSessionCalled = false;

  String? get uid => _uid;
  String? get error => _error;
  bool get isSignedIn => _isSignedIn;
  bool get hasPersistedUser => _isSignedIn;

  set uid(String? value) {
    _uid = value;
    _isSignedIn = value != null;
    notifyListeners();
  }

  Future<dynamic> signInWithGoogle() async {
    signInCalled = true;
    if (signInShouldSucceed) {
      _uid ??= 'test-uid-123';
      _error = null;
      _isSignedIn = true;
    } else {
      _error = 'Sign in failed';
    }
    notifyListeners();
    return _uid;
  }

  Future<void> signOut({
    Future<void> Function()? clearLocalSession,
  }) async {
    signOutCalled = true;
    if (clearLocalSession != null) {
      await clearLocalSession();
    }
    _uid = null;
    _error = null;
    _isSignedIn = false;
    notifyListeners();
  }

  Future<dynamic> restoreSession() async {
    restoreSessionCalled = true;
    return _uid;
  }

  Future<dynamic> reauthenticateWithGoogle() async {
    return signInWithGoogle();
  }
}

// ---------------------------------------------------------------------------
// FirebaseService (fake, no Firestore)
// ---------------------------------------------------------------------------

/// A controllable fake [FirebaseService] for tests.
class FakeFirebaseService extends ChangeNotifier {
  FakeFirebaseService({
    String? uid,
    String playerName = 'Player',
    bool needsPlayerName = false,
  })  : _uid = uid,
        _playerName = playerName,
        _needsPlayerName = needsPlayerName;

  String? _uid;
  String _playerName;
  bool _needsPlayerName;
  bool _initializing = false;
  String? _error;

  /// Controls what [deleteAccount] returns (null = success).
  String? deleteAccountError;

  /// Controls what [bootstrap] returns.
  ({int coins, int highScore, bool playerDocumentExists})? bootstrapResult;

  /// Whether [deleteAccount] was called.
  bool deleteAccountCalled = false;

  /// Whether [refreshPlayerState] was called.
  bool refreshPlayerStateCalled = false;

  /// The last name passed to [setPlayerName].
  String? lastSetPlayerName;

  final _playerNameService = FakePlayerNameService();

  // Getters
  String? get uid => _uid;
  String? get error => _error;
  bool get isSignedIn => _uid != null;
  bool get initializing => _initializing;
  bool get needsPlayerName => _needsPlayerName;
  String get playerName => _playerName;
  bool get hasPlayerName => _playerName != 'Player';
  String? get playerNameLower => _playerName.toLowerCase();
  bool get hasDefaultPlayerName => _playerName == 'Player';

  FakePlayerNameService get playerNameService => _playerNameService;

  // Setters for test control
  set uid(String? value) {
    _uid = value;
    notifyListeners();
  }

  set playerName(String value) {
    _playerName = value;
    notifyListeners();
  }

  set needsPlayerName(bool value) {
    _needsPlayerName = value;
    notifyListeners();
  }

  // Profile data helper
  Map<String, dynamic> profileData(String username,
      {int coins = 0, int highScore = 0}) {
    return {
      'uid': _uid ?? '',
      'username': username,
      'coins': coins,
      'highScore': highScore,
    };
  }

  // Core methods
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

  Future<({int coins, int highScore, bool playerDocumentExists})?>
      bootstrap({
    required int localCoins,
    required int localHighScore,
    required String avatarId,
  }) async {
    _initializing = true;
    notifyListeners();
    _initializing = false;
    notifyListeners();
    return bootstrapResult;
  }

  Future<String?> deleteAccount() async {
    deleteAccountCalled = true;
    return deleteAccountError;
  }

  void refreshPlayerState() {
    refreshPlayerStateCalled = true;
    notifyListeners();
  }

  Future<void> syncCoins(int coins) async {}

  Future<void> syncInventory({
    required String selectedBird,
    required List<String> ownedBirds,
  }) async {}

  Future<void> syncSettings({
    required bool music,
    required bool sound,
    required bool vibration,
  }) async {}
}
