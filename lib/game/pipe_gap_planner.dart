import 'dart:math';

import 'package:neon_flap1_game/models/difficulty_config.dart';

/// Generates fair, randomized gap centres.
///
/// There is deliberately no alternating high/low pattern. Each opening is
/// sampled across the complete safe band and then constrained by the maximum
/// vertical travel from the previous opening. A small anti-repeat guard keeps
/// a poor random streak from feeling like a fixed lane without ever forcing a
/// direction change.
class PipeGapPlanner {
  PipeGapPlanner({Random? random}) : _random = random ?? Random();

  final Random _random;
  double? _previousCenter;
  int _previousBand = -1;
  int _sameBandCount = 0;

  void reset() {
    _previousCenter = null;
    _previousBand = -1;
    _sameBandCount = 0;
  }

  double nextCenter({
    required double minCenter,
    required double maxCenter,
    required int score,
    required DifficultyConfig config,
  }) {
    // The score is intentionally accepted for API compatibility. Difficulty
    // already evolves maxVerticalGapChange through its configuration; the
    // random distribution itself stays unbiased at every score.
    if (score < 0) score = 0;
    if (minCenter > maxCenter) {
      throw ArgumentError.value(
        maxCenter,
        'maxCenter',
        'must be greater than or equal to minCenter',
      );
    }
    final span = maxCenter - minCenter;
    if (span <= 0) {
      _previousCenter = minCenter;
      return minCenter;
    }

    final previous = _previousCenter;
    if (previous == null) {
      final first = minCenter + span * 0.5;
      _previousCenter = first;
      _previousBand = _bandFor(first, minCenter, span);
      _sameBandCount = 1;
      return first;
    }

    final reachableMin = max(minCenter, previous - config.maxVerticalGapChange);
    final reachableMax = min(maxCenter, previous + config.maxVerticalGapChange);
    if (reachableMin > reachableMax) {
      // This can only occur with malformed configuration. Returning the
      // nearest legal centre is safer than producing an impossible gap.
      final safe = previous.clamp(minCenter, maxCenter).toDouble();
      _previousCenter = safe;
      return safe;
    }

    var candidate = _randomInRange(reachableMin, reachableMax);
    final candidateBand = _bandFor(candidate, minCenter, span);
    if (candidateBand == _previousBand && _sameBandCount >= 3) {
      // Try another random sample in the *same reachable interval*. This is
      // only a diversity hint; if all valid samples are in one band, keeping
      // that band is fairer than forcing an artificial opposite jump.
      for (var attempt = 0; attempt < 6; attempt++) {
        final alternate = _randomInRange(reachableMin, reachableMax);
        if (_bandFor(alternate, minCenter, span) != _previousBand) {
          candidate = alternate;
          break;
        }
      }
    }

    final clamped = candidate.clamp(minCenter, maxCenter).toDouble();
    final band = _bandFor(clamped, minCenter, span);
    if (band == _previousBand) {
      _sameBandCount++;
    } else {
      _sameBandCount = 1;
      _previousBand = band;
    }
    _previousCenter = clamped;
    return clamped;
  }

  double _randomInRange(double minValue, double maxValue) {
    if (minValue >= maxValue) return minValue;
    return minValue + _random.nextDouble() * (maxValue - minValue);
  }

  int _bandFor(double value, double minCenter, double span) {
    final normalized = ((value - minCenter) / span).clamp(0.0, 0.999999);
    return (normalized * 7).floor();
  }
}
