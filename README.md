# Neon Flap 2100

A futuristic cyberpunk arcade flapper built with **Flutter** + **Flame** game engine.

## Tech Stack

- Flutter + Flame Engine
- Firebase Authentication (Google Sign-In)
- Cloud Firestore
- Google AdMob (banner, interstitial, rewarded, app open)
- Google Play Billing (IAP coin packs)
- Material 3

## Setup

```bash
flutter pub get
flutter build apk --debug
flutter run
```

## GitHub Pages Setup

Legal documents (privacy policy, terms of service, data deletion) live in the `docs/` folder as markdown files with Jekyll front matter.

### To enable:

1. Go to repository **Settings → Pages**
2. Under **Source**, select **Deploy from a branch**
3. Set branch to `main` and folder to `/docs`
4. Click **Save**

GitHub Pages automatically runs Jekyll. With `permalink: pretty` configured in `docs/_config.yml`, each `.md` file renders as a clean path URL:

| Document | URL Path |
|---|---|
| Home | `/neon_flap_2100/` |
| Privacy Policy | `/neon_flap_2100/privacy-policy` |
| Terms of Service | `/neon_flap_2100/terms-of-service` |
| Data Deletion | `/neon_flap_2100/data-deletion` |

No `.html` suffix needed — Jekyll generates clean directory-style URLs.

## Running Tests

```bash
flutter analyze
flutter test
```

## Code Quality

- All rendering is procedural (Canvas) — no image sprites
- Offline-first: SharedPreferences is authoritative, Firestore is best-effort
- Object pooling for game components (pipes, coins, obstacles)
- Service locator pattern via `get_it`
