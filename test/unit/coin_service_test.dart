import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/services/coin_service.dart';

import '../helpers/mock_services.dart';

void main() {
  late FakeStorageService fakeStorage;
  late CoinService coinService;

  setUp(() {
    fakeStorage = FakeStorageService();
    coinService = CoinService(fakeStorage);
  });

  group('CoinService', () {
    test('initial state is zero', () {
      expect(coinService.coins, 0);
      expect(coinService.bestScore, 0);
    });

    test('addCoins increases balance', () async {
      await coinService.addCoins(10);
      expect(coinService.coins, 10);
    });

    test('addCoins accumulates multiple times', () async {
      await coinService.addCoins(10);
      await coinService.addCoins(5);
      await coinService.addCoins(3);
      expect(coinService.coins, 18);
    });

    test('addCoins ignores negative amounts', () async {
      await coinService.addCoins(10);
      await coinService.addCoins(-5);
      expect(coinService.coins, 10);
    });

    test('addCoins ignores zero amounts', () async {
      await coinService.addCoins(10);
      await coinService.addCoins(0);
      expect(coinService.coins, 10);
    });

    test('spendCoins decreases balance when sufficient', () async {
      await coinService.addCoins(20);
      final result = await coinService.spendCoins(5);
      expect(result, true);
      expect(coinService.coins, 15);
    });

    test('spendCoins returns false when insufficient', () async {
      await coinService.addCoins(5);
      final result = await coinService.spendCoins(10);
      expect(result, false);
      expect(coinService.coins, 5);
    });

    test('spendCoins returns true for zero amount', () async {
      await coinService.addCoins(10);
      final result = await coinService.spendCoins(0);
      expect(result, true);
      expect(coinService.coins, 10);
    });

    test('recordScore updates bestScore when higher', () async {
      await coinService.recordScore(100);
      expect(coinService.bestScore, 100);
    });

    test('recordScore does not update when lower', () async {
      await coinService.recordScore(100);
      await coinService.recordScore(50);
      expect(coinService.bestScore, 100);
    });

    test('recordScore does not update when equal', () async {
      await coinService.recordScore(100);
      await coinService.recordScore(100);
      expect(coinService.bestScore, 100);
    });

    test('setFromCloud updates coins when different', () async {
      await coinService.setFromCloud(500);
      expect(coinService.coins, 500);
    });

    test('setFromCloud does nothing when same value', () async {
      await coinService.addCoins(100);
      await coinService.setFromCloud(100);
      expect(coinService.coins, 100);
    });

    test('setBestScoreFromCloud updates bestScore', () async {
      await coinService.setBestScoreFromCloud(500);
      expect(coinService.bestScore, 500);
    });

    test('notifies listeners on addCoins', () async {
      int notifyCount = 0;
      coinService.addListener(() => notifyCount++);

      await coinService.addCoins(10);
      expect(notifyCount, 1);
    });

    test('notifies listeners on spendCoins', () async {
      await coinService.addCoins(20);

      int notifyCount = 0;
      coinService.addListener(() => notifyCount++);

      await coinService.spendCoins(5);
      expect(notifyCount, 1);
    });

    test('notifies listeners on recordScore', () async {
      int notifyCount = 0;
      coinService.addListener(() => notifyCount++);

      await coinService.recordScore(100);
      expect(notifyCount, 1);
    });
  });

  group('CoinService persistence', () {
    test('coins are persisted to storage', () async {
      await coinService.addCoins(100);

      // Create new instance with same storage
      final newService = CoinService(fakeStorage);
      await newService.load();

      expect(newService.coins, 100);
    });

    test('bestScore is persisted to storage', () async {
      await coinService.recordScore(500);

      // Create new instance with same storage
      final newService = CoinService(fakeStorage);
      await newService.load();

      expect(newService.bestScore, 500);
    });
  });
}
