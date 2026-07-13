import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neon_flap_2100/services/achievement_service.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/ad_service.dart';
import 'package:neon_flap_2100/services/billing_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/services/leaderboard_service.dart';
import 'package:neon_flap_2100/services/owned_characters_service.dart';
import 'package:neon_flap_2100/services/settings_service.dart';
import 'package:neon_flap_2100/services/storage_service.dart';
import 'package:neon_flap_2100/services/vibration_service.dart';
import 'package:neon_flap_2100/services/facebook_service.dart';

/// Global service locator (GetIt). All services are registered as singletons
/// and initialised once at startup for a single source of truth.
final GetIt sl = GetIt.instance;

/// Bootstraps all services and loads persisted state before the UI starts.
Future<void> setupServiceLocator() async {
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  sl.registerSingleton<StorageService>(storage);

  final settings = SettingsService(storage);
  await settings.load();
  sl.registerSingleton<SettingsService>(settings);

  final coins = CoinService(storage);
  await coins.load();
  sl.registerSingleton<CoinService>(coins);

  final owned = OwnedCharactersService(storage, coins);
  await owned.load();
  sl.registerSingleton<OwnedCharactersService>(owned);

  final audio = AudioService();
  await audio.init();
  sl.registerSingleton<AudioService>(audio);

  final achievements = AchievementService(storage);
  await achievements.load();
  sl.registerSingleton<AchievementService>(achievements);

  final leaderboard = LeaderboardService(storage);
  await leaderboard.load();
  sl.registerSingleton<LeaderboardService>(leaderboard);

  // Apply persisted volumes to the audio engine.
  await audio.setMusicVolume(settings.settings.musicVolume);
  await audio.setSfxVolume(settings.settings.sfxVolume);
  // React to future volume/vibration changes.
  settings.addListener(() {
    audio.setMusicVolume(settings.settings.musicVolume);
    audio.setSfxVolume(settings.settings.sfxVolume);
  });

  sl.registerSingleton<VibrationService>(VibrationService(settings));
  final adService = AdService();
  await adService.init();
  sl.registerSingleton<AdService>(adService);
  final billingService = BillingService(coins);
  await billingService.init();
  sl.registerSingleton<BillingService>(billingService);

  final facebook = FacebookService(storage);
  await facebook.init();
  sl.registerSingleton<FacebookService>(facebook);
}
