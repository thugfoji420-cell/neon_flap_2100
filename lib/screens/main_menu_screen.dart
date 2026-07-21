import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/game_screen.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/ad_service.dart';
import 'package:neon_flap1_game/services/settings_service.dart';
import 'package:neon_flap1_game/screens/google_sign_in_screen.dart';
import 'package:neon_flap1_game/store/achievements_dialog.dart';
import 'package:neon_flap1_game/store/leaderboard_dialog.dart';
import 'package:neon_flap1_game/settings/settings_screen.dart';
import 'package:neon_flap1_game/store/character_store_screen.dart';
import 'package:neon_flap1_game/store/coin_shop_screen.dart';
import 'package:neon_flap1_game/store/daily_reward_dialog.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/banner_ad_slot.dart';
import 'package:neon_flap1_game/widgets/character_avatar.dart';
import 'package:neon_flap1_game/widgets/difficulty_selector.dart';
import 'package:neon_flap1_game/widgets/holo_panel.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';
import 'package:neon_flap1_game/store/characters_data.dart';

/// Semantic spacing tokens used throughout the main menu layout.
/// Centralised so adjustments propagate consistently across breakpoints.
/// Values are kept tight while a safe scroll fallback protects short screens.
class _Spacing {
  const _Spacing._();

  static const double sectionGap = 7;
  static const double compactSectionGap = 5;
  static const double titleBottom = 8;
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  // Staggered entrance animation: each section fades+slides in sequentially.
  late final AnimationController _entranceCtrl;
  late final List<CurvedAnimation> _sectionAnimations;
  bool _isLoggingOut = false;

  T? _readService<T extends Object>() {
    try {
      return sl<T>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    // Staggered entrance: profile, play, secondary panel.
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sectionAnimations = List.generate(3, (i) {
      final start = i * 0.12;
      final end = (start + 0.30).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _entranceCtrl.forward();

    final settings = _readService<SettingsService>();
    _readService<AudioService>()
        ?.playMusic(settings?.menuTrack ?? MusicTrack.menu);
    _readService<AdService>()?.loadInterstitialAd();
  }

  @override
  void dispose() {
    for (final a in _sectionAnimations) {
      a.dispose();
    }
    _entranceCtrl.dispose();
    super.dispose();
  }

  // --- All business-logic methods preserved verbatim -----------------------

  Future<void> _play() async {
    final mode = await showDifficultySheet(context);
    if (mode == null || !mounted) return;
    await pushWithFade(
      context,
      GameScreen(mode: mode),
    );
  }

  Future<void> _exit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Exit Game?', style: NeonTextStyle.heading),
        content: const Text('Close Neon Flap 2100?', style: NeonTextStyle.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL', style: NeonTextStyle.label),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('EXIT', style: NeonTextStyle.label),
          ),
        ],
      ),
    );
    if (ok == true) SystemNavigator.pop();
  }

  Future<void> _logout() async {
    // Guard before opening the dialog as well as during sign-out. This keeps
    // rapid taps from stacking dialogs or starting two route transitions.
    if (!mounted || _isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: HoloPanel(
              color: NeonPalette.red,
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Log out?', style: NeonTextStyle.heading),
                    const SizedBox(height: 12),
                    const Text(
                      'You will need to sign in again to access your cloud progress and online features.',
                      style: NeonTextStyle.body,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(
                            label: 'CANCEL',
                            fontSize: 12,
                            height: 42,
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NeonButton(
                            label: 'LOGOUT',
                            color: NeonPalette.red,
                            fontSize: 12,
                            height: 42,
                            onPressed: () => Navigator.pop(dialogContext, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (ok != true || !mounted) return;

      final firebase = _readService<FirebaseService>();
      if (firebase == null) {
        throw StateError('Authentication service is unavailable');
      }

      // showDialog has fully removed its route before this await. Firebase
      // and Google sign-out therefore cannot rebuild a still-mounted dialog.
      await firebase.signOut();
      if (!mounted) return;
      replaceWithFade(context, const GoogleSignInScreen());
    } catch (error, stackTrace) {
      debugPrint('MainMenu logout failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _signInToSync() async {
    if (!mounted) return;
    replaceWithFade(context, const GoogleSignInScreen());
  }

  Future<void> _openLeaderboard() async {
    if (!mounted) return;
    await showLeaderboardDialog(context);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Returns a staggered [FadeTransition] + [SlideTransition] wrapper for
  /// the given section index.
  Widget _animateSection(int index, Widget child) {
    final anim = _sectionAnimations[index];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final coinService = _readService<CoinService>();
    final ownedService = _readService<OwnedCharactersService>();
    final firebaseService = _readService<FirebaseService>();
    final coinAnimation = coinService ?? ValueNotifier<int>(0);
    final ownedAnimation = ownedService ?? ValueNotifier<int>(0);
    final firebaseAnimation = firebaseService ?? ValueNotifier<int>(0);

    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.cyan,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeight = constraints.maxHeight < 620;
              final isSmall = NeonLayout.isCompact(context) || compactHeight;
              final isLarge = NeonLayout.isTablet(context);
              final basePadding = NeonLayout.screenPadding(context);
              final padding = EdgeInsets.symmetric(
                horizontal: basePadding.horizontal / 2,
                vertical: compactHeight ? 8 : 12,
              );
              final gap = compactHeight
                  ? _Spacing.compactSectionGap
                  : _Spacing.sectionGap;
              final availableHeight = (constraints.maxHeight - padding.vertical)
                  .clamp(0, double.infinity)
                  .toDouble();
              // Keep the menu sections on one shared safe width. Without a
              // minimum width, the intrinsic Column width can collapse around
              // the profile card, making the name/avatar/coins columns overlap
              // on phones even though the Play button looks wider.
              final contentWidth = isLarge
                  ? constraints.maxWidth
                      .clamp(0.0, NeonLayout.maxContentWidth)
                      .toDouble()
                  : constraints.maxWidth;

              return Padding(
                padding: padding,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: availableHeight),
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          // On wide screens, constrain the column width so
                          // the layout stays intentional rather than stretched.
                          constraints: BoxConstraints(
                            minWidth: contentWidth,
                            maxWidth: contentWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _animateSection(
                                0,
                                _buildHeader(
                                  coinService,
                                  ownedService,
                                  firebaseService,
                                  coinAnimation,
                                  ownedAnimation,
                                  firebaseAnimation,
                                  compactHeight: compactHeight,
                                ),
                              ),
                              SizedBox(height: gap),
                              _animateSection(
                                1,
                                _buildPlayCard(compactHeight: compactHeight),
                              ),
                              SizedBox(height: gap),
                              _animateSection(
                                2,
                                _buildSecondaryPanel(
                                  isSmall,
                                  compactHeight: compactHeight,
                                ),
                              ),
                              SizedBox(height: gap),
                              const BannerAdSlot(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section builders
  // -------------------------------------------------------------------------

  Widget _buildHeader(
    CoinService? coinService,
    OwnedCharactersService? ownedService,
    FirebaseService? firebaseService,
    Listenable coinAnimation,
    Listenable ownedAnimation,
    Listenable firebaseAnimation, {
    required bool compactHeight,
  }) {
    final selected = ownedService?.selected ?? CharactersData.roster.first;
    return Column(
      children: [
        Semantics(
          header: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'NEON FLAP 2100',
              style: NeonTextStyle.title.copyWith(
                fontSize: compactHeight ? 29 : NeonLayout.titleSize(context),
              ),
            ),
          ),
        ),
        SizedBox(height: _Spacing.titleBottom),
        AnimatedBuilder(
          animation: Listenable.merge([
            coinAnimation,
            ownedAnimation,
            firebaseAnimation,
          ]),
          builder: (_, __) {
            final activeCharacter = ownedService?.selected ?? selected;
            final playerName = firebaseService?.playerName ?? 'PLAYER';
            final isGuest = firebaseService?.isOfflineGuest ?? false;
            final isSynced = firebaseService?.isSignedIn ?? false;
            final scheme = Theme.of(context).colorScheme;
            final themeColors = NeonTheme.colors(context);
            final statusLabel = isGuest
                ? 'GUEST'
                : isSynced
                    ? 'SYNCED'
                    : 'LOCAL';
            final statusColor = isGuest
                ? themeColors.warning
                : isSynced
                    ? themeColors.success
                    : scheme.primary;
            final avatarZoneSize = compactHeight
                ? 78.0
                : NeonLayout.isCompact(context)
                    ? 88.0
                    : 104.0;
            final statBoxHeight = compactHeight ? 38.0 : 46.0;
            final statGap = compactHeight ? 4.0 : 6.0;
            final sideGap = compactHeight ? 6.0 : 10.0;
            final fieldHeight = statBoxHeight * 2 + statGap;

            return ProfileHudPanel(
              padding: EdgeInsets.all(compactHeight ? 10 : 12),
              child: Semantics(
                label: 'Player profile for $playerName',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: fieldHeight,
                        child: HudSection(
                          label: 'PLAYER',
                          icon: Icons.person_outline_rounded,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playerName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NeonTextStyle.body.copyWith(
                                    fontSize: compactHeight ? 11 : 13,
                                    fontWeight: FontWeight.w800,
                                    color: themeColors.hudText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isGuest
                                            ? Icons.cloud_off_outlined
                                            : isSynced
                                                ? Icons.cloud_done_outlined
                                                : Icons.storage_outlined,
                                        size: 11,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusLabel,
                                        style: NeonTextStyle.label.copyWith(
                                          fontSize: 8,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: sideGap),
                    SizedBox(
                      width: avatarZoneSize,
                      height: avatarZoneSize,
                      child: Transform.scale(
                        scale: activeCharacter.menuScale,
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: activeCharacter.menuOffset,
                          child: CharacterAvatar(
                            character: activeCharacter,
                            size: avatarZoneSize,
                            selected: true,
                            frameScale: activeCharacter.menuFrameScale,
                            artworkScale: activeCharacter.menuArtworkScale,
                            presentation: CharacterAvatarPresentation.fullBird,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: sideGap),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProfileStatBox(
                            icon: Icons.monetization_on_rounded,
                            label: 'GOLD',
                            value: coinService?.coins ?? 0,
                            accent: themeColors.gold,
                            height: statBoxHeight,
                          ),
                          SizedBox(height: statGap),
                          ProfileStatBox(
                            icon: Icons.emoji_events_rounded,
                            label: 'HIGH SCORE',
                            value: coinService?.bestScore ?? 0,
                            accent: scheme.primary,
                            height: statBoxHeight,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Primary action: PLAY with prominent sizing.
  Widget _buildPlayCard({required bool compactHeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: NeonButton(
        label: 'PLAY',
        color: NeonPalette.green,
        icon: Icons.play_arrow_rounded,
        height: compactHeight ? 54 : 62,
        fontSize: compactHeight ? 18 : 20,
        onPressed: _play,
      ),
    );
  }

  Widget _buildSecondaryPanel(
    bool isSmall, {
    required bool compactHeight,
  }) {
    final firebase = _readService<FirebaseService>();
    final isGuest = firebase?.isOfflineGuest ?? false;
    final actions = _secondaryActions(isGuest);
    return HoloPanel(
      color: NeonPalette.cyan,
      padding: EdgeInsets.all(compactHeight ? 7 : 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = 2;
          final spacing = isSmall ? 5.0 : 7.0;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: compactHeight ? 39 : 44,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return NeonButton(
                label: action.label,
                color: action.color,
                icon: action.icon,
                height: compactHeight ? 39 : 44,
                fontSize: compactHeight ? 10.8 : 12,
                onPressed: action.onPressed,
              );
            },
          );
        },
      ),
    );
  }

  List<_SecondaryAction> _secondaryActions(bool isGuest) => [
        _SecondaryAction(
          label: 'CHARACTER SHOP',
          icon: Icons.face_rounded,
          color: NeonPalette.purple,
          onPressed: () => pushWithFade(context, const CharacterStoreScreen()),
        ),
        _SecondaryAction(
          label: 'COIN SHOP',
          icon: Icons.add_circle_outline_rounded,
          color: NeonPalette.yellow,
          onPressed: () => pushWithFade(context, const CoinShopScreen()),
        ),
        _SecondaryAction(
          label: 'LEADERBOARD',
          icon: Icons.emoji_events_outlined,
          color: NeonPalette.magenta,
          onPressed: _openLeaderboard,
        ),
        _SecondaryAction(
          label: 'ACHIEVEMENTS',
          icon: Icons.military_tech_outlined,
          color: NeonPalette.green,
          onPressed: () => showAchievementsDialog(context),
        ),
        _SecondaryAction(
          label: 'DAILY REWARDS',
          icon: Icons.calendar_month_rounded,
          color: NeonPalette.yellow,
          onPressed: () => showDailyRewardDialog(context),
        ),
        _SecondaryAction(
          label: 'SETTINGS',
          icon: Icons.settings_outlined,
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => pushWithFade(context, const SettingsScreen()),
        ),
        _SecondaryAction(
          label: isGuest ? 'SIGN IN TO SYNC' : 'LOGOUT',
          icon: isGuest ? Icons.cloud_sync_outlined : Icons.logout_rounded,
          color: isGuest ? NeonPalette.cyan : NeonPalette.red,
          onPressed: isGuest ? _signInToSync : _logout,
        ),
        _SecondaryAction(
          label: 'EXIT',
          icon: Icons.power_settings_new_rounded,
          color: NeonPalette.red,
          onPressed: _exit,
        ),
      ];
}

class _SecondaryAction {
  const _SecondaryAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
}
