import 'package:flutter/material.dart';

import 'package:flame/game.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/game/game_controller.dart';
import 'package:neon_flap_2100/game/neon_flap_game.dart';
import 'package:neon_flap_2100/models/difficulty_config.dart';
import 'package:neon_flap_2100/screens/reward_screen.dart';
import 'package:neon_flap_2100/services/ad_service.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/coin_service.dart';
import 'package:neon_flap_2100/services/difficulty_service.dart';
import 'package:neon_flap_2100/services/leaderboard_service.dart';
import 'package:neon_flap_2100/services/owned_characters_service.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

/// The gameplay screen: hosts the Flame game, the HUD overlay, the countdown
/// and the in-game banner ad. On death it routes to the reward screen.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final DifficultyMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final NeonFlapGame _game;
  int _count = 3;
  bool _navigated = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.reset(DifficultyConfig.preset(widget.mode));
    final owned = sl<OwnedCharactersService>();
    _game = NeonFlapGame(
      controller: _controller,
      character: owned.selected,
      difficulty: DifficultyService(widget.mode),
    );
    _controller.addListener(_onControllerChanged);
    sl<AudioService>().stopMusic();
    sl<AudioService>().playMusic(MusicTrack.game);
    sl<AdService>().loadBanner();
    _startCountdown();
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
    sl<AudioService>().playMusic(MusicTrack.menu);
    final earned = _controller.earnedCoins;
    final score = _controller.score;
    final best = sl<CoinService>().bestScore;
    sl<LeaderboardService>().submit(score, widget.mode, sl<OwnedCharactersService>().selectedId);
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
    // Banner only lives during gameplay.
    sl<AdService>().disposeBanner();
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

  void _quit() {
    _game.resumeEngine();
    sl<AdService>().disposeBanner();
    sl<AudioService>().stopMusic();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    sl<AdService>().disposeBanner();
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (_, __) => Text(
                                  '${_controller.score}',
                                  style: NeonTextStyle.title.copyWith(fontSize: 40),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (_, __) => Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 14, color: NeonPalette.yellow),
                                    const SizedBox(width: 6),
                                    Text('${_controller.collectedCoins}',
                                        style: NeonTextStyle.heading),
                                  ],
                                ),
                              ),
                            ],
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
                        style: NeonTextStyle.title.copyWith(fontSize: 120)),
                  ),
                // Pause overlay.
                if (_paused)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: HoloPausePanel(
                        onResume: _togglePause,
                        onQuit: _quit,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Banner ad below the game.
          const _BannerAdSlot(),
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
    return GestureDetector(
      onTap: () {
        sl<AudioService>().playSfx(Sfx.buttonClick);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: NeonPalette.cyan.withOpacity(0.7)),
          color: NeonPalette.backgroundDark.withOpacity(0.6),
        ),
        child: const Icon(Icons.pause, color: NeonPalette.cyan),
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
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: NeonPalette.backgroundDark,
        border: Border.all(color: NeonPalette.cyan.withOpacity(0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('PAUSED', style: NeonTextStyle.heading),
          const SizedBox(height: 20),
          NeonButton(label: 'RESUME', color: NeonPalette.green,
              onPressed: onResume),
          const SizedBox(height: 12),
          NeonButton(label: 'QUIT', color: NeonPalette.red,
              onPressed: onQuit),
        ],
      ),
    );
  }
}

class _BannerAdSlot extends StatelessWidget {
  const _BannerAdSlot();

  @override
  Widget build(BuildContext context) {
    final ads = sl<AdService>();
    // Rebuild when the banner finishes loading/fails so it actually appears.
    return AnimatedBuilder(
      animation: ads,
      builder: (_, __) {
        final banner = ads.bannerAd;
        if (banner == null) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 50,
          child: AdWidget(ad: banner),
        );
      },
    );
  }
}
