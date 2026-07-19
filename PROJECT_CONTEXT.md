# Project Context — Neon Flap 2100

## Overview

A futuristic cyberpunk arcade flapper built with **Flutter** + **Flame** game engine. Features procedurally rendered neon graphics, 24 unlockable characters, Google Sign-In, cloud saves via Firebase Firestore, Google AdMob ads, Google Play Billing (IAP), daily rewards, achievements, and global/weekly/monthly leaderboards.

| Property | Value |
|---|---|
| **Package name** | `neon_flap1_game` |
| **Android app ID** | `com.neonflap1.game` |
| **Firebase project** | `neon-flap-2100-dfaaa` |
| **SDK** | Dart `>=3.4.0`, Flutter `>=3.22.0` |

## Quick Start

```bash
flutter pub get
flutter build apk --debug    # Build debug APK
flutter run                   # Run on connected device
flutter analyze               # Check for errors/warnings
flutter test                  # Run all tests
```

## Architecture

### Layers

1. **Screens** (`lib/screens/`) — Flutter UI widgets
2. **Game** (`lib/game/`) — Flame `FlameGame` + components (player, pipes, coins, obstacles, background)
3. **Services** (`lib/services/`) — Business logic, persistence, ads, audio, IAP
4. **Firebase** (`lib/firebase/`) — Auth, Firestore, leaderboards, daily rewards, player names
5. **Widgets** (`lib/widgets/`) — Reusable custom UI (neon buttons, panels, backgrounds)
6. **Models** (`lib/models/`) — Data classes
7. **Core** (`lib/core/`) — Constants, DI, theme, utilities

### State Management

`ChangeNotifier` + `AnimatedBuilder` throughout. Services accessed via `sl<T>()` (GetIt).

### Data Flow (Offline-First)

```
User action → CoinService (local prefs) → UI updates immediately
                                       → CoinSyncService (debounce 150ms)
                                       → Firestore (latest-wins, never deltas)
```

### Dependency Injection

All services registered in `setupServiceLocator()` (`lib/core/di/service_locator.dart`). Boot order:

1. `StorageService`
2. `ThemeController`, `SettingsService`
3. `CoinService`, `OwnedCharactersService`
4. `AudioService`, `AchievementService`, `LeaderboardService`
5. `AdService`, `BillingService`
6. `AuthService`, `FirebaseService` (bootstrap cloud profile)
7. `CoinSyncService` (attach listener)

## Key Files

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point, Firebase init, Crashlytics, DI bootstrap |
| `lib/app.dart` | MaterialApp with theme, routes |
| `lib/core/constants/app_constants.dart` | AdMob IDs, storage keys, URLs |
| `lib/core/constants/game_constants.dart` | Physics tuning values |
| `lib/core/theme/app_theme.dart` | M3 themes, neon palette, typography |
| `lib/game/neon_flap_game.dart` | Main FlameGame (world, spawning, collisions) |
| `lib/game/game_controller.dart` | Reactive run state (score, phase, coins) |
| `lib/firebase/firebase_service.dart` | Top-level Firebase facade |
| `lib/firebase/auth_service.dart` | Google Sign-In + Firebase Auth |
| `lib/firebase/daily_reward_service.dart` | 24h cooldown reward system |
| `lib/services/coin_service.dart` | Coin balance (authoritative local) |
| `lib/services/coin_sync_service.dart` | Cloud coin sync with retry |
| `lib/widgets/neon_button.dart` | Standard glowing neon button |

## Routes

| Route | Screen | Description |
|---|---|---|
| `/` | `SplashScreen` | Boot, ad, auto-restore session |
| `/menu` | `MainMenuScreen` | Hub (play, store, social, account) |
| `/game` | `GameScreen` | Flame engine + HUD |
| `/game-over` | `GameOverScreen` | Run summary |
| `/settings` | `SettingsScreen` | Volumes, theme, account |
| `/credits` | `CreditsScreen` | Attributions |
| `/store/characters` | `CharacterStoreScreen` | 24-character shop |
| `/store/coins` | `CoinShopScreen` | IAP coin packs |

## Game Mechanics

- All rendering is procedural (Canvas) — no image assets
- Object pooling for pipes, coins, obstacles
- 3 difficulty modes (Easy/Normal/Hard) with dynamic scaling
- 24 characters with 5 stats each (control, jump, gravity, hitbox, magnet)
- Gravity: 1500 px/s² | Jump impulse: -470 px/s
- Camera zoom: 0.72 (~2 upcoming pipe gaps visible)
- Collision: manual circle-vs-AABB

## Monetization

| Type | Position |
|---|---|
| App Open Ad | Cold start |
| Banner Ad | Below game, bottom of menus |
| Interstitial Ad | Between game → menu (1/3 games) |
| Rewarded Ad (2x/5x) | Game over reward choice |
| IAP coin packs | Coin shop (100–5000 coins) |

## Firebase Services

| Service | Collection |
|---|---|
| Firestore | `players`, `usernames`, `leaderboard*`, `achievements`, `inventory`, `daily_rewards`, `settings`, `cloud_save` |
| Auth | Google Sign-In (persistent sessions) |
| Crashlytics | Production error reporting |

## Testing

```bash
flutter test                          # All tests (58 tests across 5 files)
flutter test test/unit/               # Unit tests only
flutter test test/widget_test.dart    # Widget smoke tests only
```

Test helpers in `test/helpers/mock_services.dart`:
- `FakeStorageService` — in-memory SharedPreferences
- `FakeCoinService` — no-op load
- `FakeAuthService` — controllable sign-in
- `FakeFirebaseService` — controllable bootstrap
