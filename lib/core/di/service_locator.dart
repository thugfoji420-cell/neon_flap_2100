import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/widgets.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_flap1_game/services/achievement_service.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/firebase_refs.dart';
import 'package:neon_flap1_game/firebase/public_profile_service.dart';
import 'package:neon_flap1_game/firebase/auth_service.dart';
import 'package:neon_flap1_game/services/ad/ad_analytics.dart';
import 'package:neon_flap1_game/services/ad/ad_service.dart';
import 'package:neon_flap1_game/services/ad/app_open_ad_service.dart';
import 'package:neon_flap1_game/services/ad/interstitial_ad_service.dart';
import 'package:neon_flap1_game/services/ad/rewarded_ad_service.dart';
import 'package:neon_flap1_game/services/billing_service.dart';
import 'package:neon_flap1_game/firebase/ad_reward_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/coin_sync_service.dart';
import 'package:neon_flap1_game/services/leaderboard_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/settings_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/services/vibration_service.dart';
import 'package:neon_flap1_game/firebase/player_name_generator_service.dart';
import 'package:neon_flap1_game/core/theme/theme_controller.dart';

/// Global service locator (GetIt). All services are registered as singletons
/// and initialised once at startup for a single source of truth.
final GetIt sl = GetIt.instance;

/// Bootstraps all services and loads persisted state before the UI starts.
Future<void> setupServiceLocator() async {
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  sl.registerSingleton<StorageService>(storage);

  // Theme selection is loaded before the app starts to avoid a visible flash
  // from the system theme to a previously selected preference.
  final themeController = ThemeController(storage);
  await themeController.load();
  sl.registerSingleton<ThemeController>(themeController);

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

  sl.registerSingleton<VibrationService>(VibrationService(settings));
  final adAnalytics = AdAnalytics();
  final interstitialAdService = InterstitialAdService(storage, adAnalytics);
  final appOpenAdService = AppOpenAdService(adAnalytics);
  final rewardedAdService = RewardedAdService(storage, adAnalytics);
  final adRewardSync =
      AdRewardService(FirebaseRefs(FirebaseFirestore.instance));
  final adService = AdService(
    adAnalytics,
    interstitialAdService,
    appOpenAdService,
    rewardedAdService,
    adRewardSync,
  );
  await adService.init();
  sl.registerSingleton<AdService>(adService);
  final billingService = BillingService(coins);
  await billingService.init();
  sl.registerSingleton<BillingService>(billingService);

  // Firebase: sign in anonymously, load/create the cloud profile and adopt the
  // best cloud values (coins / high score) so progress is restored.
  final authService = AuthService(FirebaseAuth.instance);
  sl.registerSingleton<AuthService>(authService);

  final firebaseService = FirebaseService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    authService,
  );
  final bootstrap = await firebaseService.bootstrap(
    localCoins: coins.coins,
    localHighScore: coins.bestScore,
    avatarId: owned.selectedId,
  );
  await firebaseService.applyBootstrap(bootstrap, coins);
  sl.registerSingleton<FirebaseService>(firebaseService);

  final usernameGenerator = PlayerNameGeneratorService(
    firestore: FirebaseFirestore.instance,
  );
  sl.registerSingleton<PlayerNameGeneratorService>(usernameGenerator);

  final publicProfile = PublicProfileService(FirebaseFirestore.instance);
  sl.registerSingleton<PublicProfileService>(publicProfile);

  final coinSync = CoinSyncService(storage);
  coinSync.attach();
  sl.registerSingleton<CoinSyncService>(coinSync);

  // Auto-sync pending coins when the app returns from the background or the OS
  // reports restored connectivity (covers offline → online transitions).
  _lifecycleObserver = _CoinSyncLifecycle(coinSync);
  // Guaranteed non-null: assigned on the line above (no async gap).
  WidgetsBinding.instance.addObserver(_lifecycleObserver!);

  _onOwnedChanged = () {
    firebaseService.syncInventory(
      selectedBird: owned.selectedId,
      ownedBirds: owned.unlocked.toList(),
    );
  };
  owned.addListener(_onOwnedChanged!);

  _onSettingsChanged = () {
    final s = settings.settings;
    firebaseService.syncSettings(
      music: s.musicVolume > 0,
      sound: s.sfxVolume > 0,
      vibration: s.vibration,
    );
  };
  settings.addListener(_onSettingsChanged!);

  _onAudioSettingsChanged = () {
    audio.setMusicVolume(settings.settings.musicVolume);
    audio.setSfxVolume(settings.settings.sfxVolume);
  };
  settings.addListener(_onAudioSettingsChanged!);
}

/// Tears down all service-locator-level observers and listeners. Safe to call
/// from test tearDown or app shutdown. Leaves the [GetIt] container intact so
/// [sl.reset] can be called independently.
void disposeServiceLocator() {
  final observer = _lifecycleObserver;
  if (observer != null) {
    WidgetsBinding.instance.removeObserver(observer);
    _lifecycleObserver = null;
  }
  // Detach the CoinSyncService listener so it stops queueing flushes.
  try {
    sl<CoinSyncService>().detach();
  } catch (_) {
    // Not registered yet — ignored.
  }
  // Remove ChangeNotifier listeners registered during setup.
  try {
    if (_onOwnedChanged != null) {
      sl<OwnedCharactersService>().removeListener(_onOwnedChanged!);
      _onOwnedChanged = null;
    }
    if (_onSettingsChanged != null) {
      sl<SettingsService>().removeListener(_onSettingsChanged!);
      _onSettingsChanged = null;
    }
    if (_onAudioSettingsChanged != null) {
      sl<SettingsService>().removeListener(_onAudioSettingsChanged!);
      _onAudioSettingsChanged = null;
    }
  } catch (_) {
    // Services may already have been reset.
  }
}

/// Pushes any pending coin total to the cloud when the app resumes from the
/// background, so coins collected before an interruption are never lost and any
/// offline queue is flushed as soon as the device is back online.
class _CoinSyncLifecycle extends WidgetsBindingObserver {
  _CoinSyncLifecycle(this._coinSync);
  final CoinSyncService _coinSync;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _coinSync.onConnectivityRestored();
    }
  }
}

/// Holds the lifecycle observer so it can be removed on teardown. Exposed for
/// test cleanup; in production the observer lives for the app process.
_CoinSyncLifecycle? _lifecycleObserver;

/// ChangeNotifier listener callbacks registered during [setupServiceLocator].
/// Stored so [disposeServiceLocator] can remove them.
VoidCallback? _onOwnedChanged;
VoidCallback? _onSettingsChanged;
VoidCallback? _onAudioSettingsChanged;
