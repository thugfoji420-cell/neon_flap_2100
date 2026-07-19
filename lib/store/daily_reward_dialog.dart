import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/daily_reward_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

/// Daily login reward dialog with animated claim, 24h countdown, and a 7-day
/// cycle progress indicator.
Future<void> showDailyRewardDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _DailyRewardDialog(),
  );
}

class _DailyRewardDialog extends StatefulWidget {
  const _DailyRewardDialog();

  @override
  State<_DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<_DailyRewardDialog>
    with TickerProviderStateMixin {
  DailyRewardStatus? _status;
  bool _busy = false;
  Timer? _countdownTimer;

  // Celebration animation.
  late final AnimationController _celebrateCtrl;
  late final Animation<double> _celebrateScale;
  late final Animation<double> _celebrateFade;

  // Particle spark positions for the burst effect.
  final List<_Spark> _sparks = [];
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _celebrateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _celebrateScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _celebrateCtrl, curve: Curves.elasticOut),
    );
    _celebrateFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrateCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _celebrateCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading & claim
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    final firebase = sl<FirebaseService>();
    final status = await firebase.dailyRewardStatus();
    if (mounted) {
      setState(() => _status = status);
      _startCountdown(status);
    }
  }

  /// Ticks every 30s to keep the remaining time display up to date.
  void _startCountdown(DailyRewardStatus status) {
    _countdownTimer?.cancel();
    if (status.canClaim || status.remainingMillis <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        final s = _status;
        if (s == null) return;
        final remaining = math.max(0, s.remainingMillis - 30000);
        _status = DailyRewardStatus(
          day: s.day,
          streak: s.streak,
          canClaim: remaining <= 0,
          rewardCoins: s.rewardCoins,
          lastClaim: s.lastClaim,
          remainingMillis: remaining,
          pendingOffline: s.pendingOffline,
        );
      });
    });
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final firebase = sl<FirebaseService>();
    final gained = await firebase.claimDailyReward();
    if (gained > 0) {
      await sl<CoinService>().addCoins(gained);
      sl<AudioService>().playSfx(Sfx.rewardReceived);
      _celebrateCtrl.forward(from: 0);
      _generateSparks();
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  void _generateSparks() {
    _sparks.clear();
    for (int i = 0; i < 24; i++) {
      _sparks.add(_Spark(
        angle: _rnd.nextDouble() * math.pi * 2,
        speed: 60 + _rnd.nextDouble() * 140,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: NeonPanel(
        padding: EdgeInsets.zero,
        borderColor: NeonPalette.yellow,
        shadowColor: NeonPalette.yellow,
        shadowOpacity: 0.2,
        child: Stack(
          children: [
            // Main content — wrapped in LayoutBuilder for responsive sizing.
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return Padding(
                  padding: EdgeInsets.all(isNarrow ? 16 : 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(scheme, isNarrow),
                        const SizedBox(height: 16),
                        if (status == null)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: NeonPalette.yellow,
                              ),
                            ),
                          )
                        else ...[
                          if (status.pendingOffline)
                            _buildOfflineBanner(scheme),
                          _buildDayCycle(scheme, isNarrow),
                          const SizedBox(height: 16),
                          _buildRewardCard(status, scheme, isNarrow),
                          const SizedBox(height: 20),
                          _buildAction(status),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            // Spark particle layer.
            if (_celebrateCtrl.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _celebrateCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _SparkPainter(
                        _sparks,
                        _celebrateCtrl.value,
                        NeonPalette.yellow,
                      ),
                    ),
                  ),
                ),
              ),
            // Celebratory reward overlay.
            if (_celebrateCtrl.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _celebrateCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _celebrateFade.value,
                      child: Transform.scale(
                        scale: _celebrateScale.value,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: NeonPalette.yellow,
                                size: 48 * _celebrateScale.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, bool isNarrow) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DAILY REWARDS',
                style: NeonTextStyle.heading.copyWith(
                  fontSize: isNarrow ? 18 : 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: sl<FirebaseService>(),
                builder: (_, __) => Text(
                  'PLAYER: ${sl<FirebaseService>().playerName.toUpperCase()}',
                  style: NeonTextStyle.label.copyWith(
                    fontSize: isNarrow ? 10 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        NeonButton(
          label: 'CLOSE',
          color: NeonPalette.red,
          fontSize: isNarrow ? 12 : 14,
          height: isNarrow ? 32 : 36,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// Inline banner shown when a reward was claimed offline and is pending
  /// cloud sync.
  Widget _buildOfflineBanner(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NeonPalette.yellow.withOpacity(0.1),
        border: Border.all(color: NeonPalette.yellow.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, size: 16, color: NeonPalette.yellow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'REWARD CLAIMED OFFLINE — WILL SYNC WHEN ONLINE',
              style: NeonTextStyle.label.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows all 7 days of the reward cycle, highlighting the current day and
  /// dimming future / past days.
  Widget _buildDayCycle(ColorScheme scheme, bool isNarrow) {
    final status = _status!;
    // Compute the maximum circle size that fits 7 items across available width.
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final availablePerDay = (maxWidth - 40) / 7;
    final circleSize = (availablePerDay - 12).clamp(16.0, isNarrow ? 28.0 : 36.0);
    final isCurrentSize = (circleSize * 1.25).clamp(20.0, isNarrow ? 32.0 : 40.0);
    final fontSize = (circleSize * 0.42).clamp(9.0, 15.0);
    final coinFontSize = (circleSize * 0.32).clamp(7.0, 10.0);
    final labelFont = isNarrow ? 10.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAY ${status.day} OF 7  ·  STREAK: ${status.streak}',
          style: NeonTextStyle.label.copyWith(fontSize: labelFont),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (i) {
            final dayNum = i + 1;
            final isCurrent = dayNum == status.day;
            final isPast = dayNum < status.day;
            final color = isCurrent
                ? NeonPalette.yellow
                : isPast
                    ? NeonPalette.green
                    : scheme.onSurfaceVariant;
            final opacity = isCurrent || isPast ? 1.0 : 0.35;
            final sz = isCurrent ? isCurrentSize : circleSize;
            return Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: sz,
                    height: sz,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(isCurrent ? 0.2 : 0.1),
                      border: Border.all(
                        color: color.withOpacity(isCurrent ? 0.9 : 0.4),
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontFamily: NeonTextStyle.fontFamily,
                        fontSize: isCurrent ? fontSize + 2 : fontSize,
                        fontWeight: FontWeight.w700,
                        color: color.withOpacity(opacity),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DailyRewardService.cycleRewards[i]}',
                    style: TextStyle(
                      fontFamily: NeonTextStyle.fontFamily,
                      fontSize: coinFontSize,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(opacity * 0.7),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRewardCard(DailyRewardStatus status, ColorScheme scheme, bool isNarrow) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: NeonTheme.colors(context).field,
        border: Border.all(color: NeonPalette.yellow.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: isNarrow ? 36 : 48,
            height: isNarrow ? 36 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NeonPalette.yellow.withOpacity(0.15),
              border: Border.all(color: NeonPalette.yellow),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: NeonPalette.yellow,
              size: isNarrow ? 18 : 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${status.rewardCoins} COINS',
                    style: NeonTextStyle.heading.copyWith(
                      fontSize: isNarrow ? 18 : 22,
                    ),
                  ),
                ),
                Text(
                  'DAY ${status.day} REWARD',
                  style: NeonTextStyle.label.copyWith(
                    fontSize: isNarrow ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),
          if (!status.canClaim && !status.pendingOffline)
            _buildCountdown(status, isNarrow),
        ],
      ),
    );
  }

  /// Shows a compact "Xh Ym" countdown until the next claim is available.
  Widget _buildCountdown(DailyRewardStatus status, bool isNarrow) {
    final remaining = status.remainingMillis;
    if (remaining <= 0) return const SizedBox.shrink();

    final hours = remaining ~/ (60 * 60 * 1000);
    final minutes = (remaining % (60 * 60 * 1000)) ~/ (60 * 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${hours}h ${minutes}m',
            style: NeonTextStyle.heading.copyWith(
              fontSize: isNarrow ? 16 : 20,
              color: NeonPalette.cyan,
            ),
          ),
        ),
        Text(
          'NEXT CLAIM',
          style: NeonTextStyle.label.copyWith(
            fontSize: isNarrow ? 9 : 10,
          ),
        ),
      ],
    );
  }

  /// Claim button or disabled state. When the claim was just made (celebration
  /// animation playing) shows the animation.
  Widget _buildAction(DailyRewardStatus status) {
    if (_celebrateCtrl.isAnimating) {
      return AnimatedBuilder(
        animation: _celebrateCtrl,
        builder: (_, __) => Opacity(
          opacity: (1.0 - _celebrateCtrl.value).clamp(0.0, 1.0),
          child: NeonButton(
            label: 'CLAIMED!',
            color: NeonPalette.green,
            onPressed: null,
          ),
        ),
      );
    }

    if (status.canClaim) {
      return NeonButton(
        label: _busy ? 'CLAIMING...' : 'CLAIM REWARD',
        color: NeonPalette.yellow,
        onPressed: _busy ? null : _claim,
      );
    }

    return AnimatedBuilder(
      animation: sl<CoinService>(),
      builder: (_, __) => NeonButton(
        label: 'ALREADY CLAIMED',
        onPressed: null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spark particle system for the claim celebration
// ---------------------------------------------------------------------------

class _Spark {
  _Spark({required this.angle, required this.speed});
  final double angle;
  final double speed;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.sparks, this.progress, this.color);
  final List<_Spark> sparks;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final s in sparks) {
      final t = progress * 0.9;
      final d = t * s.speed;
      final pos = Offset(
        center.dx + math.cos(s.angle) * d,
        center.dy + math.sin(s.angle) * d,
      );
      final life = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withOpacity(life * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 4 * life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.progress != progress;
}
