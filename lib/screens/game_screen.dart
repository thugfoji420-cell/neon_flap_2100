import 'package:flutter/material.dart';

import 'package:flame/game.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/game/game_controller.dart';
import 'package:neon_flap1_game/game/neon_flap_game.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';
import 'package:neon_flap1_game/screens/reward_screen.dart';
import 'package:neon_flap1_game/services/ad_service.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/services/difficulty_service.dart';
import 'package:neon_flap1_game/services/leaderboard_service.dart';
import 'package:neon_flap1_game/services/owned_characters_service.dart';
import 'package:neon_flap1_game/services/settings_service.dart';
import 'package:neon_flap1_game/widgets/banner_ad_slot.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// The gameplay screen: hosts the Flame game, the HUD overlay, the countdown
/// and the in-game banner ad. On death it routes to the reward screen.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final DifficultyMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController _controller;
  late final NeonFlapGame _game;
  int _count = 3;
  bool _navigated = false;
  bool _paused = false;
  bool _pausedForLifecycle = false;
  bool _gameCreated = false;
  bool _controllerAttached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _controller = GameController();
      _controller.reset(DifficultyConfig.preset(widget.mode));
      final owned = sl<OwnedCharactersService>();
      _game = NeonFlapGame(
        controller: _controller,
        character: owned.selected,
        difficulty: DifficultyService(widget.mode),
      );
      _gameCreated = true;
      _controller.addListener(_onControllerChanged);
      _controllerAttached = true;
      sl<AudioService>().stopMusic();
      sl<AudioService>().playMusic(sl<SettingsService>().gameplayTrack);
      sl<AdService>().loadInterstitialAd();
      _game.loadFuture.then((_) => _startCountdown());
    } catch (e) {
      sl<AudioService>().stopMusic();
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      if (!mounted) return false;
      if (_count > 0) {
        sl<AudioService>().playSfx(Sfx.countdown);
      }
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_count == 1) {
        setState(() => _count = 0);
        _game.startPlay();
        return false;
      }
      setState(() => _count--);
      return true;
    });
  }

  void _onControllerChanged() {
    if (_controller.phase == GamePhase.gameOver && !_navigated) {
      _navigated = true;
      _toReward();
    }
  }

  Future<void> _toReward() async {
    sl<AudioService>().stopMusic();
    sl<AudioService>().playMusic(sl<SettingsService>().menuTrack);
    final earned = _controller.earnedCoins;
    final score = _controller.score;
    final best = sl<CoinService>().bestScore;
    sl<LeaderboardService>()
        .submit(score, widget.mode, sl<OwnedCharactersService>().selectedId);
    if (!mounted) return;
    await showRewardDialog(
      context: context,
      earnedCoins: earned,
      score: score,
      best: best,
      mode: widget.mode,
      characterId: sl<OwnedCharactersService>().selectedId,
      totalFlaps: _controller.totalFlaps,
    );
  }

  void _togglePause() {
    if (_navigated) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeFromLifecycle();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseForLifecycle();
    }
  }

  /// Screen-off/background must freeze the Flame engine so a player cannot
  /// lose a run while the phone is asleep. The game resumes only when it was
  /// actively running before the interruption, never over a manual pause.
  void _pauseForLifecycle() {
    if (_navigated || _paused || _pausedForLifecycle || !_gameCreated) return;
    _pausedForLifecycle = true;
    _game.pauseEngine();
  }

  void _resumeFromLifecycle() {
    if (_navigated || _paused || !_pausedForLifecycle || !_gameCreated) {
      return;
    }
    _pausedForLifecycle = false;
    _game.resumeEngine();
  }

  void _quit() {
    _pausedForLifecycle = false;
    _game.resumeEngine();
    sl<AudioService>().stopMusic();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controllerAttached) _controller.removeListener(_onControllerChanged);
    if (_gameCreated) _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameHud = NeonTheme.colors(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _game.flap(),
                  child: GameWidget(game: _game),
                ),
                // HUD (transparent, taps fall through to the game).
                IgnorePointer(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Padding(
                            // The pause target occupies the upper-right edge.
                            // Reserving its full touch target prevents overlap
                            // with a long coin total on narrow devices.
                            padding: const EdgeInsets.only(right: 58),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (_, __) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${_controller.score}',
                                          style: NeonTextStyle.title.copyWith(
                                            fontSize: 32,
                                            color: gameHud.hudText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (_, __) => Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 12,
                                              color: gameHud.gold,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_controller.collectedCoins}',
                                              style: NeonTextStyle.heading
                                                  .copyWith(
                                                fontSize: 18,
                                                color: gameHud.hudText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
                // Pause button (interactive).
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: _PauseButton(onTap: _togglePause),
                ),
                // Countdown overlay.
                if (_count > 0)
                  Center(
                    child: Text('$_count',
                        style: NeonTextStyle.title.copyWith(
                          fontSize: 120,
                          color: gameHud.hudText,
                        )),
                  ),
                // Pause overlay.
                if (_paused)
                  Container(
                    color:
                        Theme.of(context).colorScheme.scrim.withOpacity(0.54),
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: NeonLayout.screenPadding(context),
                          child: HoloPausePanel(
                            onResume: _togglePause,
                            onQuit: _quit,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Banner ad below the game.
          const BannerAdSlot(),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeColors = NeonTheme.colors(context);
    return Semantics(
      button: true,
      label: 'Pause game',
      child: Material(
        color: themeColors.hudSurface.withValues(alpha: 0.92),
        shape: CircleBorder(
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.7)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            sl<AudioService>().playSfx(Sfx.buttonClick);
            onTap();
          },
          child: SizedBox.square(
            dimension: NeonLayout.minimumTapTarget,
            child: Icon(Icons.pause, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}

class HoloPausePanel extends StatelessWidget {
  const HoloPausePanel({
    super.key,
    required this.onResume,
    required this.onQuit,
  });
  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final themeColors = NeonTheme.colors(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NeonLayout.panelRadius),
          color: themeColors.hudSurface,
          border: Border.all(color: themeColors.hudBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'PAUSED',
                style:
                    NeonTextStyle.heading.copyWith(color: themeColors.hudText),
              ),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              color: NeonPalette.green,
              onPressed: onResume,
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'QUIT',
              icon: Icons.close_rounded,
              color: NeonPalette.red,
              onPressed: onQuit,
            ),
          ],
        ),
      ),
    );
  }
}
