import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/player_name_generator_service.dart';
import 'package:neon_flap1_game/firebase/player_name_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';

/// Availability states for the player name input.
enum _AvailabilityStatus {
  idle,
  checking,
  available,
  taken,
  invalid,
  networkError,
}

/// Full-screen first-launch player name picker. The game cannot continue until a
/// valid, globally-unique player name is claimed. Network failures surface inline
/// so the player can retry without being stuck.
class ChoosePlayerNameScreen extends StatefulWidget {
  const ChoosePlayerNameScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<ChoosePlayerNameScreen> createState() => _ChoosePlayerNameScreenState();
}

class _ChoosePlayerNameScreenState extends State<ChoosePlayerNameScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final AnimationController _glowAnim;
  late final Animation<double> _glowPulse;

  bool _checking = false;
  String? _inlineError;

  _AvailabilityStatus _status = _AvailabilityStatus.idle;
  String? _availabilityMessage;
  Timer? _debounceTimer;
  Timer? _scanTimer;
  double _scanProgress = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();

    _glowAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowPulse = CurvedAnimation(parent: _glowAnim, curve: Curves.easeInOut);

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scanTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _anim.dispose();
    _glowAnim.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.isEmpty) {
      _setStatus(_AvailabilityStatus.idle);
      return;
    }

    final validator = sl<FirebaseService>().playerNameService.validator;
    final error = validator.validate(text);

    if (error != null) {
      _setStatus(_AvailabilityStatus.invalid);
      return;
    }

    _setStatus(_AvailabilityStatus.idle);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _checkAvailability(text);
    });
  }

  void _setStatus(_AvailabilityStatus status) {
    setState(() {
      _status = status;
      switch (status) {
        case _AvailabilityStatus.idle:
          _availabilityMessage = null;
          _scanProgress = 0;
          break;
        case _AvailabilityStatus.checking:
          _availabilityMessage = 'SCANNING DATABASE...';
          _inlineError = null;
          break;
        case _AvailabilityStatus.available:
          _availabilityMessage = 'PLAYER NAME AVAILABLE';
          _scanProgress = 1;
          break;
        case _AvailabilityStatus.taken:
          _availabilityMessage = 'PLAYER NAME TAKEN';
          _scanProgress = 0;
          break;
        case _AvailabilityStatus.invalid:
          _availabilityMessage = null;
          _scanProgress = 0;
          break;
        case _AvailabilityStatus.networkError:
          _availabilityMessage = 'NETWORK ERROR';
          _scanProgress = 0;
          break;
      }
    });
  }

  Future<void> _checkAvailability(String value) async {
    if (value.isEmpty) return;

    _setStatus(_AvailabilityStatus.checking);
    _startScanAnimation();

    final firebase = sl<FirebaseService>();
    final uid = firebase.uid;

    if (uid == null) {
      _stopScanAnimation();
      _setStatus(_AvailabilityStatus.networkError);
      return;
    }

    try {
      final repo = firebase.playerNameService;
      final lower = repo.toLookupKey(value);
      final taken =
          firebase.playerNameService.validator.validate(value) != null;

      if (!mounted) return;

      if (taken) {
        _stopScanAnimation();
        _setStatus(_AvailabilityStatus.invalid);
        return;
      }

      final isTaken = await _checkIfTaken(lower, uid).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('_checkIfTaken timed out after 10 seconds');
          }
          if (!mounted) return false;
          _stopScanAnimation();
          _setStatus(_AvailabilityStatus.networkError);
          return false;
        },
      );
      if (!mounted) return;

      _stopScanAnimation();
      _setStatus(
          isTaken ? _AvailabilityStatus.taken : _AvailabilityStatus.available);
    } catch (_) {
      _stopScanAnimation();
      _setStatus(_AvailabilityStatus.networkError);
    }
  }

  Future<bool> _checkIfTaken(String lower, String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('usernames').doc(lower).get();
      if (!doc.exists) return false;
      final owner = doc.data()?['uid'] as String?;
      return owner != uid;
    } catch (_) {
      return false;
    }
  }

  void _startScanAnimation() {
    _scanTimer?.cancel();
    _scanProgress = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _scanProgress = (_scanProgress + 0.05).clamp(0.0, 0.95);
      });
    });
  }

  void _stopScanAnimation() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  void _generateRandom() async {
    setState(() {
      _checking = true;
      _inlineError = null;
    });

    final generator = sl<PlayerNameGeneratorService>();
    final available = await generator.findAvailable();

    if (!mounted) return;

    setState(() {
      _checking = false;
    });

    if (available != null) {
      _controller.text = available;
      _onTextChanged();
    } else {
      setState(() {
        _inlineError = 'Could not find an available player name. Try again.';
        _setStatus(_AvailabilityStatus.networkError);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_status != _AvailabilityStatus.available) {
      _checkAvailability(_controller.text);
      return;
    }

    setState(() {
      _checking = true;
      _inlineError = null;
    });

    final firebase = sl<FirebaseService>();
    final uid = firebase.uid;
    if (uid == null) {
      setState(() {
        _checking = false;
        _inlineError = 'Network error. Please retry.';
      });
      return;
    }

    PlayerNameResult result;
    try {
      result = await firebase.playerNameService
          .claim(firebase.profileData(_controller.text), _controller.text)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        if (kDebugMode) debugPrint('claim() timed out after 15 seconds');
        return PlayerNameResult.error;
      });
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
            'FirebaseException during claim: code=${e.code} message=${e.message}');
      }
      result = PlayerNameResult.error;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Exception during claim: $e');
      }
      result = PlayerNameResult.error;
    }

    if (!mounted) return;
    switch (result) {
      case PlayerNameResult.success:
        if (kDebugMode) {
          debugPrint('Username claimed successfully, navigating to MainMenu');
        }
        firebase.player.updateUsername(_controller.text);
        firebase.refreshPlayerState();
        try {
          widget.onComplete();
        } catch (e) {
          if (kDebugMode) debugPrint('Navigation failed: $e');
          if (mounted) {
            setState(() => _checking = false);
          }
        }
        return;
      case PlayerNameResult.taken:
        setState(() {
          _checking = false;
          _inlineError = 'This player name is already taken.';
          _setStatus(_AvailabilityStatus.taken);
        });
        break;
      case PlayerNameResult.invalid:
        setState(() {
          _checking = false;
          _inlineError = 'Invalid player name.';
          _setStatus(_AvailabilityStatus.invalid);
        });
        break;
      case PlayerNameResult.error:
        setState(() {
          _checking = false;
          _inlineError = 'Network error. Please retry.';
          _setStatus(_AvailabilityStatus.networkError);
        });
        break;
    }
  }

  Color _getStatusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (_status) {
      case _AvailabilityStatus.idle:
        return scheme.primary;
      case _AvailabilityStatus.checking:
        return scheme.tertiary;
      case _AvailabilityStatus.available:
        return scheme.secondary;
      case _AvailabilityStatus.taken:
        return scheme.error;
      case _AvailabilityStatus.invalid:
        return scheme.error;
      case _AvailabilityStatus.networkError:
        return scheme.error;
    }
  }

  Widget _buildAvailabilityIndicator(BuildContext context) {
    final color = _getStatusColor(context);
    final text = _availabilityMessage;

    if (_status == _AvailabilityStatus.idle) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.6)),
        color: color.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status == _AvailabilityStatus.checking)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: _scanProgress,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else ...[
            Icon(
              _status == _AvailabilityStatus.available
                  ? Icons.check_circle_rounded
                  : _status == _AvailabilityStatus.networkError
                      ? Icons.wifi_off_rounded
                      : Icons.error_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 10),
          ],
          if (text != null)
            Text(
              text,
              style: TextStyle(
                fontFamily: NeonTextStyle.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: color,
                shadows: [Shadow(color: color, blurRadius: 8)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharCounter(BuildContext context) {
    final length = _controller.text.length;
    final maxLength = 16;
    final scheme = Theme.of(context).colorScheme;
    final color = length > maxLength
        ? scheme.error
        : length >= maxLength - 2
            ? scheme.tertiary
            : scheme.primary;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontFamily: NeonTextStyle.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: color,
      ),
      child: Text('$length / $maxLength'),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final color = _getStatusColor(context);
    if (_status == _AvailabilityStatus.checking) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: _scanProgress,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (_status == _AvailabilityStatus.available) {
      return Icon(
        Icons.check_circle_rounded,
        size: 22,
        color: color,
      );
    }

    if (_status == _AvailabilityStatus.taken ||
        _status == _AvailabilityStatus.invalid ||
        _status == _AvailabilityStatus.networkError) {
      return Icon(
        Icons.cancel_rounded,
        size: 22,
        color: color,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final firebase = sl<FirebaseService>();
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.cyan,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth =
                    constraints.maxWidth > 500 ? 480.0 : double.infinity;
                final horizontalPadding =
                    constraints.maxWidth > 500 ? 28.0 : 20.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isSmallScreen ? 16 : 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(context),
                            SizedBox(height: isSmallScreen ? 20 : 32),
                            _buildInputSection(
                                context, firebase, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            _buildRandomButton(context, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _buildContinueButton(context),
                            if (_inlineError != null) ...[
                              SizedBox(height: 16),
                              _buildInlineError(context),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              scheme.primary,
              NeonPalette.magenta,
              NeonPalette.purple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'NEON FLAP',
            style: NeonTextStyle.title,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              scheme.primary,
              scheme.onSurface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            '2100',
            style: NeonTextStyle.heading.copyWith(
              color: scheme.primary,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.primary.withOpacity(0.4)),
            color: scheme.primary.withOpacity(0.05),
          ),
          child: Text(
            'CHOOSE YOUR PLAYER NAME',
            style: TextStyle(
              fontFamily: NeonTextStyle.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: scheme.primary,
              shadows: [Shadow(color: scheme.primary, blurRadius: 12)],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(
    BuildContext context,
    FirebaseService firebase,
    bool isSmallScreen,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final themeColors = NeonTheme.colors(context);
    final borderColor = _getStatusColor(context);
    final isAvailable = _status == _AvailabilityStatus.available;
    final isTaken = _status == _AvailabilityStatus.taken;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor.withOpacity(0.7),
          width: isAvailable || isTaken ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.35),
            blurRadius: isAvailable ? 24 : 14,
            spreadRadius: isAvailable ? 2 : 1,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            borderColor.withOpacity(0.06),
            themeColors.panel,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PILOT PLAYER NAME',
                  style: TextStyle(
                    fontFamily: NeonTextStyle.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: scheme.primary,
                  ),
                ),
              ),
              _buildCharCounter(context),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controller,
            autofocus: true,
            enabled: !_checking,
            maxLength: 16,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            style: NeonTextStyle.heading.copyWith(
              fontSize: isSmallScreen ? 18 : 22,
              letterSpacing: 1.5,
              color: scheme.onSurface,
              shadows: [
                Shadow(
                  color: borderColor.withOpacity(0.6),
                  blurRadius: 16,
                ),
              ],
            ),
            decoration: InputDecoration(
              hintText: 'ENTER PLAYER NAME...',
              hintStyle: TextStyle(
                fontFamily: NeonTextStyle.fontFamily,
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: scheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: themeColors.field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: scheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: scheme.outline,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: scheme.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: scheme.error,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isSmallScreen ? 16 : 20,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildStatusIcon(context),
              ),
              counterStyle: const TextStyle(height: 0),
              counterText: '',
            ),
            validator: (v) {
              final error = firebase.playerNameService.validateFormat(v ?? '');
              if (error != null) {
                _setStatus(_AvailabilityStatus.invalid);
                return null;
              }
              return null;
            },
            onChanged: (_) {
              if (_inlineError != null) {
                setState(() => _inlineError = null);
              }
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 6),
          _buildAvailabilityIndicator(context),
        ],
      ),
    );
  }

  Widget _buildRandomButton(BuildContext context, bool isSmallScreen) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _checking ? null : _generateRandom,
        icon: AnimatedBuilder(
          animation: _glowPulse,
          builder: (context, child) {
            return Icon(
              Icons.casino_rounded,
              size: 18,
              color: _checking
                  ? scheme.primary.withOpacity(0.4)
                  : scheme.primary.withOpacity(0.7 + _glowPulse.value * 0.3),
            );
          },
        ),
        label: Text(
          'GENERATE RANDOM PLAYER NAME',
          style: TextStyle(
            fontFamily: NeonTextStyle.fontFamily,
            fontSize: isSmallScreen ? 11 : 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: _checking
                ? scheme.primary.withOpacity(0.4)
                : scheme.primary.withOpacity(0.9),
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: scheme.primary.withOpacity(0.3),
            ),
          ),
          backgroundColor: scheme.primary.withOpacity(0.04),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final isAvailable = _status == _AvailabilityStatus.available;
    final canSubmit = isAvailable && !_checking;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: canSubmit
              ? [
                  scheme.secondary.withOpacity(0.9),
                  scheme.secondary.withOpacity(0.6),
                ]
              : [
                  scheme.primary.withOpacity(0.15),
                  scheme.primary.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: canSubmit
              ? scheme.secondary.withOpacity(0.9)
              : scheme.primary.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: canSubmit
            ? [
                BoxShadow(
                  color: scheme.secondary.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSubmit ? _submit : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _checking
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.onSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'CONNECTING...',
                        style: TextStyle(
                          fontFamily: NeonTextStyle.fontFamily,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          fontSize: 15,
                          color: scheme.onSecondary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    isAvailable ? 'ENTER THE GRID' : 'CONNECT',
                    style: TextStyle(
                      fontFamily: NeonTextStyle.fontFamily,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      fontSize: 15,
                      color: canSubmit
                          ? scheme.onSecondary
                          : scheme.primary.withOpacity(0.5),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineError(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final msg = _inlineError;
    if (msg == null) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: error.withOpacity(0.6)),
        color: error.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_rounded,
            size: 16,
            color: error,
          ),
          const SizedBox(width: 10),
          Text(
            msg,
            style: TextStyle(
              fontFamily: NeonTextStyle.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: error,
            ),
          ),
        ],
      ),
    );
  }
}
