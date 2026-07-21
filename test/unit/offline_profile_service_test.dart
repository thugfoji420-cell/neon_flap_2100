import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/core/constants/app_constants.dart';
import 'package:neon_flap1_game/services/offline_profile_service.dart';

import '../helpers/mock_services.dart';

void main() {
  late FakeStorageService storage;
  late OfflineProfileService service;

  setUp(() async {
    storage = FakeStorageService();
    service = OfflineProfileService(storage);
    await service.load();
  });

  test('startSession creates a stable incomplete guest profile', () async {
    final result = await service.startSession();

    expect(result, OfflineProfileStart.needsPlayerName);
    expect(service.guestId, startsWith('guest_'));
    expect(storage.getBool(StorageKeys.hasOfflineProfile), true);
    expect(storage.getBool(StorageKeys.isOfflinePlayer), true);
    expect(storage.getBool(StorageKeys.offlineProfileComplete), false);
  });

  test('completeProfile persists guest name and active session', () async {
    await service.startSession();
    await service.completeProfile('NeonPilot');

    expect(service.isGuestSessionActive, true);
    expect(service.playerName, 'NeonPilot');
    expect(storage.getString(StorageKeys.offlinePlayerName), 'NeonPilot');
    expect(storage.getBool(StorageKeys.offlineProfileComplete), true);
  });

  test('load repairs a completed profile with missing player name', () async {
    await storage.setBool(StorageKeys.hasOfflineProfile, true);
    await storage.setBool(StorageKeys.offlineProfileComplete, true);
    await storage.setBool(StorageKeys.isOfflinePlayer, true);

    final restored = OfflineProfileService(storage);
    await restored.load();

    expect(restored.isGuestSessionActive, false);
    expect(restored.hasIncompleteOfflineProfile, true);
    expect(storage.getBool(StorageKeys.offlineProfileComplete), false);
  });

  test('leaveSession saves progress snapshot without deleting profile',
      () async {
    await service.startSession();
    await service.completeProfile('GridRunner');
    await storage.setInt(StorageKeys.coins, 125);
    await storage.setInt(StorageKeys.bestScore, 42);
    await storage
        .setStringList(StorageKeys.unlockedCharacters, ['nova', 'ion']);

    await service.leaveSession();

    expect(service.isGuestSessionActive, false);
    expect(service.hasOfflineProfile, true);
    expect(service.hasSnapshot, true);
    expect(storage.getBool(StorageKeys.isOfflinePlayer), false);
    expect(service.snapshot?.coins, 125);
    expect(service.snapshot?.bestScore, 42);
  });

  test('startSession restores saved progress snapshot for returning guest',
      () async {
    await service.startSession();
    await service.completeProfile('GridRunner');
    await storage.setInt(StorageKeys.coins, 90);
    await storage.setInt(StorageKeys.bestScore, 7);
    await service.leaveSession();
    await storage.setInt(StorageKeys.coins, 0);
    await storage.setInt(StorageKeys.bestScore, 0);

    final result = await service.startSession();

    expect(result, OfflineProfileStart.ready);
    expect(storage.getInt(StorageKeys.coins), 90);
    expect(storage.getInt(StorageKeys.bestScore), 7);
  });

  test('completed migration deactivates old guest without deleting backup',
      () async {
    await service.startSession();
    await service.completeProfile('SyncPilot');
    await storage.setInt(StorageKeys.coins, 210);
    await service.saveProgressSnapshot();
    final oldGuestId = service.guestId;

    await service.markMigrationInProgress();
    await service.markMigrationCompleted(cloudUid: 'google_uid_1');

    expect(service.hasOfflineProfile, false);
    expect(service.isGuestSessionActive, false);
    expect(service.hasSnapshot, true);
    expect(service.migrationStatus, GuestMigrationStatus.completed);
    expect(service.migrationCloudUid, 'google_uid_1');
    expect(service.migrationId, oldGuestId);

    final result = await service.startSession();

    expect(result, OfflineProfileStart.needsPlayerName);
    expect(service.guestId, isNot(oldGuestId));
    expect(storage.getBool(StorageKeys.offlineProfileComplete), false);
  });
}
