# Neon Flap 2100 Production Release Checklist

---

## CODE QUALITY

- [ ] flutter analyze
- [ ] flutter test
- [ ] No compile errors
- [ ] No analyzer warnings
- [ ] No runtime crashes
- [ ] No memory leaks
- [ ] No duplicate code

---

## GAMEPLAY

- [ ] Physics verified
- [ ] Camera verified
- [ ] Pipe generation verified
- [ ] Difficulty verified
- [ ] Coin rewards verified
- [ ] Daily Reward verified
- [ ] Game Over verified
- [ ] Pause verified
- [ ] Resume verified

---

## FIREBASE

- [ ] Google Login
- [ ] Logout
- [ ] Firestore
- [ ] Coin Sync
- [ ] Daily Reward
- [ ] Leaderboard
- [ ] Rewarded Ads
- [ ] User isolation
- [ ] Security Rules verified

---

## ADS

- [ ] Banner Ads
- [ ] Rewarded Ads
- [ ] Test Ads removed
- [ ] Production Ad Unit IDs
- [ ] app-ads.txt verified

---

## UI

- [ ] Responsive
- [ ] Material 3
- [ ] No overflow
- [ ] No clipped widgets
- [ ] Buttons aligned
- [ ] Text fits
- [ ] Animations smooth

---

## PERFORMANCE

- [ ] Smooth gameplay
- [ ] No frame drops
- [ ] Low memory usage
- [ ] Images cached
- [ ] Audio optimized
- [ ] Firestore optimized

---

## ANDROID

- [ ] Release signing
- [ ] Keystore
- [ ] Version Code
- [ ] Version Name
- [ ] Java 17
- [ ] AndroidX
- [ ] R8
- [ ] ProGuard
- [ ] Hardware acceleration

---

## PLAY STORE

- [ ] App Icon
- [ ] Feature Graphic
- [ ] Screenshots
- [ ] Privacy Policy
- [ ] Terms
- [ ] Data Safety
- [ ] Content Rating
- [ ] Ads declaration
- [ ] App Category
- [ ] Target SDK
- [ ] Min SDK

---

## SECURITY

- [ ] No hardcoded secrets
- [ ] API keys secured
- [ ] Firebase configured
- [ ] Release SHA added
- [ ] Debug code removed

---

## TESTING

Test on:

- [ ] Android 11
- [ ] Android 12
- [ ] Android 13
- [ ] Android 14
- [ ] Android 15
- [ ] Small screen
- [ ] Medium screen
- [ ] Large screen
- [ ] Tablet
- [ ] Low RAM device
- [ ] High refresh rate device
- [ ] Offline mode
- [ ] Poor internet
- [ ] Fast internet
- [ ] Google account switching
- [ ] Rewarded ads
- [ ] Daily reward
- [ ] Shop
- [ ] Leaderboard

---

## FINAL BUILD

- [ ] flutter clean
- [ ] flutter pub get
- [ ] flutter analyze
- [ ] flutter test
- [ ] flutter build appbundle
- [ ] flutter build apk --release

Verify:

- [ ] AAB builds successfully
- [ ] APK installs
- [ ] No startup crash
- [ ] Firebase works
- [ ] Ads work
- [ ] Coins sync
- [ ] Daily Reward works
- [ ] Leaderboard works

---

## PRE-PUBLISH

- [ ] Final gameplay review
- [ ] Review every screen
- [ ] Review every dialog
- [ ] Review every button
- [ ] Review every animation
- [ ] Review all Firebase collections
- [ ] Review Crashlytics
- [ ] Review Analytics
- [ ] Review AdMob
- [ ] Review Play Console settings

---

## READY FOR RELEASE

Only publish when every item above has been verified.
