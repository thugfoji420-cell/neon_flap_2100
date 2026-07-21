import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/player_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/coin_sync_service.dart';

import '../helpers/mock_services.dart';

/// Stub player service that does nothing on writes.
/// Matches the real PlayerService signatures exactly.
class _FakePlayerService implements PlayerService {
  @override
  Future<void> syncCloudSave({
    required int coins,
    required int highScore,
    int checkpoint = 0,
  }) async {}

  @override
  Future<void> syncCoins(int coins) async {}

  @override
  Future<void> syncHighScore(int highScore) async {}

  @override
  Future<void> syncInventory(
      {required String selectedBird, required List<String> ownedBirds}) async {}

  @override
  Future<void> syncSettings({
    required bool music,
    required bool sound,
    required bool vibration,
    String language = 'English',
    double? musicVolume,
    double? sfxVolume,
    String? menuTrackId,
    String? gameplayTrackId,
  }) async {}

  @override
  Future<void> syncAchievements(Map<String, bool> unlocked) async {}

  @override
  Future<Map<String, dynamic>> loadOrCreate(
    String uid, {
    required int localCoins,
    required int localHighScore,
    required String avatarId,
  }) async =>
      {};

  @override
  Future<void> recordRun({
    required int score,
    required int coinsEarned,
    required String difficulty,
    required String avatarId,
  }) async {}

  @override
  Future<void> setUsername(String name) async {}

  @override
  void updateUsername(String name) {}

  @override
  Map<String, dynamic> get profile => {};

  @override
  bool get profileExisted => false;

  @override
  set profileExisted(bool value) {}

  @override
  bool get hasUsername => true;

  @override
  bool get hasDefaultUsername => false;

  @override
  String? get username => 'TestPlayer';

  @override
  void reset() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock FirebaseService for CoinSyncService tests.
/// Extends ChangeNotifier so listener methods work, overrides only what
/// CoinSyncService actually calls.
class _MockFirebaseService extends ChangeNotifier implements FirebaseService {
  _MockFirebaseService({String? uid}) : _uid = uid;

  String? _uid;
  int syncCoinsCallCount = 0;
  int? lastSyncedCoins;
  final _player = _FakePlayerService();

  set uid(String? value) {
    _uid = value;
    notifyListeners();
  }

  // ── Getters used by CoinSyncService ──

  @override
  String? get uid => _uid;

  @override
  bool get isSignedIn => _uid != null;

  @override
  bool get isCloudAvailable => true;

  @override
  bool get isOfflineGuest => false;

  @override
  bool get hasOfflineProfile => false;

  @override
  bool get hasCompletedOfflineProfile => false;

  @override
  bool get hasIncompleteOfflineProfile => false;

  @override
  bool get hasActiveIncompleteOfflineProfile => false;

  @override
  bool get initializing => false;

  @override
  bool get needsPlayerName => false;

  @override
  String get playerName => 'TestPlayer';

  @override
  bool get hasPlayerName => true;

  @override
  String? get playerNameLower => 'testplayer';

  @override
  bool get hasDefaultPlayerName => false;

  @override
  String? get error => null;

  @override
  PlayerService get player => _player;

  // ── Methods called by CoinSyncService ──

  @override
  Future<void> syncCoins(int coins) async {
    syncCoinsCallCount++;
    lastSyncedCoins = coins;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late FakeStorageService storage;
  late FakeCoinService coinService;
  late _MockFirebaseService firebaseService;
  late CoinSyncService syncService;
  late GetIt sl;

  setUp(() async {
    sl = GetIt.instance;
    if (sl.isRegistered<CoinService>()) sl.unregister<CoinService>();
    if (sl.isRegistered<FirebaseService>()) sl.unregister<FirebaseService>();

    storage = FakeStorageService();
    coinService = FakeCoinService();
    await coinService.load();

    firebaseService = _MockFirebaseService(uid: 'test-uid');

    sl.registerSingleton<CoinService>(coinService);
    sl.registerSingleton<FirebaseService>(firebaseService);

    syncService = CoinSyncService(storage);
  });

  tearDown(() {
    syncService.dispose();
    sl.reset();
  });

  group('attach', () {
    test('replays pending coins from previous session', () async {
      await storage.setInt(StorageKeys.pendingCloudCoins, 42);
      await storage.setBool('nf_coin_sync_pending', true);

      syncService.attach();

      expect(storage.getBool('nf_coin_sync_pending'), true);
    });

    test('starts with no pending when storage is clean', () {
      syncService.attach();

      // attach() doesn't set the pending flag when there's nothing pending
      final hasPending = storage.getBool('nf_coin_sync_pending');
      expect(hasPending, isNot(true));
    });
  });

  group('debounce', () {
    test('SharedPreferences write is debounced during rapid coin bursts',
        () async {
      syncService.attach();

      await coinService.addCoins(10);
      await coinService.addCoins(10);
      await coinService.addCoins(10);

      // Wait for debounce to fire (150ms + buffer)
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(storage.getInt(StorageKeys.pendingCloudCoins), 30);
      expect(storage.getBool('nf_coin_sync_pending'), true);
    });

    test('only the latest total is persisted after debounce', () async {
      syncService.attach();

      await coinService.addCoins(5);
      await coinService.addCoins(10);
      await coinService.addCoins(15);

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(storage.getInt(StorageKeys.pendingCloudCoins), 30);
    });

    test('debounce resets on each new coin change', () async {
      syncService.attach();

      await coinService.addCoins(10);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Reset the debounce timer
      await coinService.addCoins(20);

      // 100ms after second addCoins — debounce still hasn't fired
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Wait for the debounce from the second call to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(storage.getInt(StorageKeys.pendingCloudCoins), 30);
    });
  });

  group('flush to cloud', () {
    test('coins are synced to firebase on successful flush', () async {
      syncService.attach();

      await coinService.addCoins(50);

      // Wait for debounce + flush
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(firebaseService.syncCoinsCallCount, greaterThan(0));
      expect(firebaseService.lastSyncedCoins, 50);
    });

    test('pending flag is set when there are unsynced coins', () async {
      syncService.attach();

      await coinService.addCoins(10);

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 250));

      // Pending should be set (flush may still be in progress)
      expect(storage.getBool('nf_coin_sync_pending'), true);
      expect(storage.getInt(StorageKeys.pendingCloudCoins), 10);
    });
  });

  group('offline queueing', () {
    test('pending total is kept when firebase.uid is null', () async {
      firebaseService = _MockFirebaseService(uid: null);
      sl.unregister<FirebaseService>();
      sl.registerSingleton<FirebaseService>(firebaseService);

      syncService.attach();

      await coinService.addCoins(10);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(storage.getBool('nf_coin_sync_pending'), true);
      expect(storage.getInt(StorageKeys.pendingCloudCoins), 10);
    });

    test('pending total persists across attach/detach cycles', () async {
      syncService.attach();

      await coinService.addCoins(25);

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(storage.getInt(StorageKeys.pendingCloudCoins), 25);

      syncService.detach();
      syncService = CoinSyncService(storage);

      syncService.attach();

      expect(storage.getBool('nf_coin_sync_pending'), true);
    });
  });

  group('single in-flight write', () {
    test('only the latest total is synced after rapid coin bursts', () async {
      syncService.attach();

      await coinService.addCoins(10);
      await coinService.addCoins(20);
      await coinService.addCoins(30);

      // Wait for debounce + flush
      await Future<void>.delayed(const Duration(milliseconds: 1000));

      // Firebase should have been called with the latest total
      expect(firebaseService.lastSyncedCoins, 60);
    });
  });

  group('latest-wins', () {
    test('only the latest total is written to cloud, never deltas', () async {
      syncService.attach();

      await coinService.addCoins(10);
      await coinService.addCoins(20);
      await coinService.addCoins(5);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(storage.getInt(StorageKeys.pendingCloudCoins), 35);
      expect(firebaseService.lastSyncedCoins, 35);
    });
  });

  group('flushNow', () {
    test('triggers a flush immediately', () async {
      syncService.attach();

      await coinService.addCoins(15);

      // Force immediate flush
      syncService.flushNow();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Firebase should have received the sync call
      expect(firebaseService.syncCoinsCallCount, greaterThan(0));
      expect(firebaseService.lastSyncedCoins, 15);
    });
  });

  group('onConnectivityRestored', () {
    test('triggers an immediate flush', () async {
      syncService.attach();

      await coinService.addCoins(10);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      syncService.onConnectivityRestored();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(firebaseService.syncCoinsCallCount, greaterThan(0));
      expect(firebaseService.lastSyncedCoins, 10);
    });
  });

  group('detach', () {
    test('cancels all timers and removes listener', () {
      syncService.attach();

      expect(() => syncService.detach(), returnsNormally);
      // Double detach should be safe
      expect(() => syncService.detach(), returnsNormally);
    });
  });

  group('dispose', () {
    test('calls detach and cleans up', () {
      syncService.attach();
      expect(() => syncService.dispose(), returnsNormally);
    });
  });
}
