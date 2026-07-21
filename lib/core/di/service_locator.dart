import 'dart:async';

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
import 'package:neon_flap1_game/services/offline_profile_service.dart';
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
Future<void> setupServiceLocator({bool firebaseEnabled = true}) async {
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  sl.registerSingleton<StorageService>(storage);

  final offlineProfile = OfflineProfileService(storage);
  await offlineProfile.load();
  sl.registerSingleton<OfflineProfileService>(offlineProfile);

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
  FirebaseAuth? firebaseAuth;
  FirebaseFirestore? firestore;
  if (firebaseEnabled) {
    try {
      firebaseAuth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firebase services unavailable during setup: $e');
      firebaseAuth = null;
      firestore = null;
    }
  }

  final adRewardSync =
      AdRewardService(firestore == null ? null : FirebaseRefs(firestore));
  final adService = AdService(
    adAnalytics,
    interstitialAdService,
    appOpenAdService,
    rewardedAdService,
    adRewardSync,
  );
  try {
    await adService.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Ad service unavailable during setup: $e');
  }
  sl.registerSingleton<AdService>(adService);
  final billingService = BillingService(coins);
  try {
    await billingService.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Billing service unavailable during setup: $e');
  }
  sl.registerSingleton<BillingService>(billingService);

  // Firebase services are registered even when cloud startup fails, but in that
  // case they expose a disabled sign-in path while offline guest play remains.
  final authService =
      firebaseAuth == null ? AuthService.disabled() : AuthService(firebaseAuth);
  sl.registerSingleton<AuthService>(authService);

  final firebaseService = FirebaseService(
    firebaseAuth,
    firestore,
    authService,
    offlineProfile,
  );
  sl.registerSingleton<FirebaseService>(firebaseService);

  final usernameGenerator = PlayerNameGeneratorService(
    firestore: firestore,
  );
  sl.registerSingleton<PlayerNameGeneratorService>(usernameGenerator);

  if (firestore != null) {
    final publicProfile = PublicProfileService(firestore);
    sl.registerSingleton<PublicProfileService>(publicProfile);
  }

  final coinSync = CoinSyncService(storage);
  sl.registerSingleton<CoinSyncService>(coinSync);

  // Auto-sync pending coins when the app returns from the background or the OS
  // reports restored connectivity (covers offline → online transitions).
  _lifecycleObserver = _AppLifecycleObserver(coinSync, audio);
  // Guaranteed non-null: assigned on the line above (no async gap).
  WidgetsBinding.instance.addObserver(_lifecycleObserver!);

  _onOwnedChanged = () {
    firebaseService.syncInventory(
      selectedBird: owned.selectedId,
      ownedBirds: owned.allKnownOwnedIds.toList(),
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
    final currentTrack = audio.currentTrack;
    audio.setMusicVolume(settings.settings.musicVolume);
    audio.setSfxVolume(settings.settings.sfxVolume);
    if (currentTrack?.category == MusicCategory.menu &&
        currentTrack != settings.menuTrack) {
      audio.playMusic(settings.menuTrack);
    } else if (currentTrack?.category == MusicCategory.gameplay &&
        currentTrack != settings.gameplayTrack) {
      audio.playMusic(settings.gameplayTrack);
    }
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
class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver(this._coinSync, this._audio);
  final CoinSyncService _coinSync;
  final AudioService _audio;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _coinSync.onConnectivityRestored();
      unawaited(_audio.resumeAfterAppLifecycle());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_audio.pauseForAppLifecycle());
    }
  }
}

/// Holds the lifecycle observer so it can be removed on teardown. Exposed for
/// test cleanup; in production the observer lives for the app process.
_AppLifecycleObserver? _lifecycleObserver;

/// ChangeNotifier listener callbacks registered during [setupServiceLocator].
/// Stored so [disposeServiceLocator] can remove them.
VoidCallback? _onOwnedChanged;
VoidCallback? _onSettingsChanged;
VoidCallback? _onAudioSettingsChanged;
