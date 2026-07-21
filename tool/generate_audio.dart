// Audio asset generator for Neon Flap 2100.
//
// This script synthesizes all runtime sound effects as 16-bit PCM mono WAV
// files so the game ships with functional audio without requiring external
// binary dependencies. The music loops are original synth arrangements built
// around the neon arcade / runner identity of the game.
//
// Run with:  dart run tool/generate_audio.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;

double note(num semitonesFromA4) => 440.0 * pow(2.0, semitonesFromA4 / 12.0);

/// Convert a list of mono float samples in [-1, 1] to 16-bit PCM WAV bytes.
Uint8List encodeWav(List<double> samples) {
  final bytes = BytesBuilder();
  final dataSize = samples.length * 2;
  // RIFF header
  bytes.add(ascii('RIFF'));
  bytes.addUint32(dataSize + 36);
  bytes.add(ascii('WAVE'));
  // fmt chunk
  bytes.add(ascii('fmt '));
  bytes.addUint32(16);
  bytes.addUint16(1); // PCM
  bytes.addUint16(1); // mono
  bytes.addUint32(sampleRate);
  bytes.addUint32(sampleRate * 2); // byte rate
  bytes.addUint16(2); // block align
  bytes.addUint16(16); // bits per sample
  // data chunk
  bytes.add(ascii('data'));
  bytes.addUint32(dataSize);
  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    final int v = (clamped * 32767).round();
    bytes.addUint16(v & 0xFFFF);
  }
  return bytes.toBytes();
}

extension on BytesBuilder {
  void addUint16(int v) {
    add([v & 0xFF, (v >> 8) & 0xFF]);
  }

  void addUint32(int v) {
    add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
  }

  void addAscii(String s) => add(s.codeUnits);
}

List<int> ascii(String s) => s.codeUnits;

/// Simple attack/decay envelope.
double env(double t, double dur, double attack, double release) {
  if (t < attack) return t / attack;
  if (t > dur - release) return max(0.0, (dur - t) / release);
  return 1.0;
}

/// Additive tone with optional FM shimmer for a "cyber" feel.
double tone(double t, double freq, {double fm = 0, double fmAmount = 0}) {
  double f = freq;
  if (fm > 0) f += sin(2 * pi * fm * t) * fmAmount;
  return sin(2 * pi * f * t);
}

List<double> render(int durationSamples, double Function(double t) fn) {
  final out = List<double>.filled(durationSamples, 0.0);
  for (int i = 0; i < durationSamples; i++) {
    out[i] = fn(i / sampleRate);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Individual sound effects
// ---------------------------------------------------------------------------

List<double> buttonClick() => render(
      (0.08 * sampleRate).toInt(),
      (t) =>
          0.25 *
          env(t, 0.08, 0.005, 0.05) *
          (tone(t, note(16)) + 0.4 * tone(t, note(23))),
    );

List<double> tap() => render(
      (0.12 * sampleRate).toInt(),
      (t) =>
          0.35 *
          env(t, 0.12, 0.002, 0.09) *
          (tone(t, note(24), fm: 900, fmAmount: 120) + 0.3 * tone(t, note(31))),
    );

List<double> coin() => render(
      (0.18 * sampleRate).toInt(),
      (t) {
        final f = note(28) + 600 * t;
        return 0.3 *
            env(t, 0.18, 0.003, 0.07) *
            (sin(2 * pi * f * t) + 0.5 * sin(2 * pi * (f * 1.5) * t));
      },
    );

List<double> characterUnlock() {
  final notesSeq = [12, 16, 19, 24];
  return render((0.6 * sampleRate).toInt(), (t) {
    final idx = min(notesSeq.length - 1, (t / 0.15).floor());
    return 0.3 * env(t, 0.6, 0.01, 0.2) * tone(t, note(notesSeq[idx]));
  });
}

List<double> purchaseSuccess() {
  final notesSeq = [16, 21, 24, 28];
  return render((0.5 * sampleRate).toInt(), (t) {
    final idx = min(notesSeq.length - 1, (t / 0.12).floor());
    return 0.32 * env(t, 0.5, 0.01, 0.15) * tone(t, note(notesSeq[idx]));
  });
}

List<double> rewardReceived() {
  final notesSeq = [19, 24, 28, 31, 36];
  return render((0.7 * sampleRate).toInt(), (t) {
    final idx = min(notesSeq.length - 1, (t / 0.14).floor());
    return 0.34 * env(t, 0.7, 0.01, 0.2) * tone(t, note(notesSeq[idx]));
  });
}

List<double> gameOver() => render(
      (1.2 * sampleRate).toInt(),
      (t) => 0.35 * env(t, 1.2, 0.01, 0.5) * tone(t, note(8) * (1 - t / 2.4)),
    );

List<double> countdown() => render(
      (0.15 * sampleRate).toInt(),
      (t) => 0.3 * env(t, 0.15, 0.003, 0.08) * tone(t, note(20)),
    );

List<double> victory() {
  final notesSeq = [24, 28, 31, 36, 40];
  return render((0.9 * sampleRate).toInt(), (t) {
    final idx = min(notesSeq.length - 1, (t / 0.18).floor());
    return 0.34 * env(t, 0.9, 0.01, 0.25) * tone(t, note(notesSeq[idx]));
  });
}

/// Background music dispatcher retained for quick local previews.
List<double> music({bool game = false}) =>
    game ? gameGridRunner() : menuNeonDawn();

/// Smooth but energetic, futuristic menu music: warm chord pads plus a gentle
/// pulsing bass and a driving soft arpeggio and lead. All rhythmic voices use
/// phase-reset soft envelopes, so there is movement/energy without harsh
/// transients, and the 16s loop is seamless.
List<double> _menuMusic() {
  const chordDur = 4.0; // seconds per chord
  const progression = [
    [-9, -2, 3, 7],
    [-4, 0, 5, 9],
    [-7, -2, 2, 7],
    [-5, 0, 4, 9],
  ];
  final bars = progression.length;
  final dur = chordDur * bars; // 16s seamless loop
  final total = (dur * sampleRate).toInt();

  const beat = 0.5; // 120 BPM pulse
  const arpStep = 0.25; // eighth-note arpeggio
  const arpPattern = [0, 1, 2, 3, 2, 1]; // indices into the chord
  const melody = [12, 14, 16, 14]; // soft lead over the top
  const melodyStep = 1.0;

  return render(total, (t) {
    final chordIdx = (t / chordDur).floor() % bars;
    final chord = progression[chordIdx];
    final local = t % chordDur;
    final padEnv = 0.5 - 0.5 * cos(2 * pi * (local / chordDur));
    final lfo = 0.85 + 0.15 * sin(2 * pi * 0.06 * t);

    // Warm detuned pad (adds body/warmth).
    double pad = 0.0;
    for (final semi in chord) {
      final f = note(semi);
      pad += sin(2 * pi * f * t) + sin(2 * pi * f * 1.004 * t);
      pad += 0.2 * sin(2 * pi * f * 2 * t);
    }
    pad *= 0.022 * padEnv * lfo;

    // Pulsing bass on every beat (phase-reset -> clean & seamless).
    final bIdx = (t / beat).floor();
    final bLocal = t - bIdx * beat;
    final bf = note(chord[0] - 12);
    final bEnv = exp(-bLocal * 6.0) * (1 - (bLocal / beat)).clamp(0.0, 1.0);
    final bass = 0.11 * bEnv * sin(2 * pi * bf * bLocal);

    // Driving soft arpeggio (eighth notes), gentle in/out per note.
    final aIdx = (t / arpStep).floor();
    final aLocal = t - aIdx * arpStep;
    final af = note(chord[arpPattern[aIdx % arpPattern.length]] + 12);
    final aEnv = sin(pi * (aLocal / arpStep).clamp(0.0, 1.0));
    final arp = 0.055 *
        aEnv *
        (sin(2 * pi * af * aLocal) + 0.25 * sin(2 * pi * af * 2 * aLocal));

    // Soft melodic lead for a hook.
    final mIdx = (t / melodyStep).floor();
    final mLocal = t - mIdx * melodyStep;
    double lead = 0.0;
    if (mIdx * melodyStep <= dur - melodyStep - 0.0001) {
      final mf = note(melody[mIdx % melody.length]);
      final mEnv = sin(pi * (mLocal / melodyStep).clamp(0.0, 1.0));
      lead = 0.045 * mEnv * sin(2 * pi * mf * mLocal);
    }

    return pad + bass + arp + lead;
  });
}

/// Calm, futuristic ambient music for gameplay: slowly evolving warm chord
/// pads, gentle detuned chorus and sparse soft bells. Designed to loop
/// seamlessly (the pad swells to zero at every chord edge, and bells never
/// start close enough to the loop point to click).
List<double> _relaxingGameMusic() {
  const chordDur = 4.0; // seconds per chord
  // Soothing progression as semitone offsets from A4 for each chord tone.
  const progression = [
    [-9, -5, -2, 2],
    [-7, -3, 0, 5],
    [-12, -8, -5, 0],
    [-10, -5, -1, 3],
  ];
  final bars = progression.length;
  final dur = chordDur * bars; // 16s seamless loop
  final total = (dur * sampleRate).toInt();
  const arpStep = 1.0; // one soft bell per second

  return render(total, (t) {
    final chordIdx = (t / chordDur).floor() % bars;
    final chord = progression[chordIdx];
    final local = t % chordDur;
    // Smooth swell to zero at each chord edge for seamless crossfades.
    final padEnv = 0.5 - 0.5 * cos(2 * pi * (local / chordDur));
    // Slow tremolo for gentle movement.
    final lfo = 0.85 + 0.15 * sin(2 * pi * 0.07 * t);

    double pad = 0.0;
    for (final semi in chord) {
      final f = note(semi);
      // Two slightly detuned oscillators = warm chorus, plus an airy octave.
      pad += sin(2 * pi * f * t) + sin(2 * pi * f * 1.004 * t);
      pad += 0.22 * sin(2 * pi * f * 2 * t);
    }
    pad *= 0.03 * padEnv * lfo;

    // Sparse soft bells on chord tones (one octave up), long gentle decay.
    double bell = 0.0;
    final idx = (t / arpStep).floor();
    final start = idx * arpStep;
    if (start <= dur - 1.6) {
      final bt = t - start;
      final bf = note(chord[idx % chord.length] + 12);
      final e = exp(-bt * 2.0);
      bell =
          0.045 * e * (sin(2 * pi * bf * t) + 0.25 * sin(2 * pi * bf * 2 * t));
    }

    return pad + bell;
  });
}

List<double> _cyberLoop({
  required List<List<int>> progression,
  required List<int> melody,
  required double bpm,
  required double duration,
  required double rootShift,
  required double bassMix,
  required double arpMix,
  required double leadMix,
  required double shimmer,
}) {
  final total = (duration * sampleRate).toInt();
  final chordDur = duration / progression.length;
  final beat = 60.0 / bpm;
  final arpStep = beat / 4;
  const arpPattern = [0, 1, 2, 3, 2, 1, 0, 2];

  // Harmonic oscillators deliberately use sine-based partials rather than a
  // hard digital saw. The result stays polished and smooth on phone speakers
  // while still carrying enough bite for a neon runner soundtrack.
  double synth(double time, double frequency, {double brightness = 1}) {
    return sin(2 * pi * frequency * time) +
        0.34 * brightness * sin(2 * pi * frequency * 2 * time) +
        0.12 * brightness * sin(2 * pi * frequency * 3 * time);
  }

  double kick(double local, {required bool accent}) {
    if (local > 0.30) return 0;
    final attack = sin(pi * (local / 0.014).clamp(0.0, 1.0));
    final decay = exp(-local * 13.5);
    final frequency = 46 + 104 * exp(-local * 21);
    return (accent ? 0.25 : 0.18) *
        attack *
        decay *
        sin(2 * pi * frequency * local);
  }

  // Deterministic multi-sine noise: crisp enough for hats/claps but softer
  // than raw random white noise, which sounded harsh in the previous loops.
  double digitalNoise(double local) =>
      (sin(2 * pi * 1739 * local) +
          sin(2 * pi * 2671 * local) +
          sin(2 * pi * 3919 * local)) /
      3;

  return render(total, (t) {
    final chordIndex = (t / chordDur).floor() % progression.length;
    final chord = progression[chordIndex];
    final localChord = t % chordDur;
    final padEnv = 0.5 - 0.5 * cos(2 * pi * (localChord / chordDur));
    final beatIndex = (t / beat).floor();
    final beatLocal = t - beatIndex * beat;
    final beatInBar = beatIndex % 4;
    // Gentle side-chain movement makes the pads breathe around the kick.
    final sidechain = 0.72 + 0.28 * (1 - exp(-beatLocal * 10));
    final slowLfo = 0.84 + 0.16 * sin(2 * pi * (0.05 + shimmer * 0.012) * t);

    double pad = 0;
    for (final semi in chord) {
      final f = note(semi + rootShift);
      pad += synth(t, f, brightness: 0.42);
      pad += 0.68 * synth(t, f * (1.002 + shimmer * 0.0008), brightness: 0.3);
    }
    pad *= 0.019 * padEnv * slowLfo * sidechain;

    // Pulsing sub bass alternates the root and fifth on off-beats so every
    // track feels like it is moving forward instead of sitting on a pad.
    final bassStep = beat / 2;
    final bassIndex = (t / bassStep).floor();
    final bassLocal = t - bassIndex * bassStep;
    final bassSemitone = bassIndex.isEven ? chord[0] : chord[2];
    final bassFreq = note(bassSemitone + rootShift - 12);
    final bassEnv = exp(-bassLocal * (7.0 + shimmer)) *
        sin(pi * (bassLocal / bassStep).clamp(0.0, 1.0));
    final bass =
        bassMix * bassEnv * synth(bassLocal, bassFreq, brightness: 0.34);

    final arpIndex = (t / arpStep).floor();
    final arpLocal = t - arpIndex * arpStep;
    final arpFreq =
        note(chord[arpPattern[arpIndex % arpPattern.length]] + rootShift + 12);
    final arpEnv = sin(pi * (arpLocal / arpStep).clamp(0, 1));
    final arp = arpMix * arpEnv * synth(arpLocal, arpFreq, brightness: 1.0);

    // A clean FM-like lead supplies the recognisable sci-fi hook.
    final leadStep = beat;
    final leadIndex = (t / leadStep).floor();
    final leadLocal = t - leadIndex * leadStep;
    final leadFreq = note(melody[leadIndex % melody.length] + rootShift + 12);
    final leadEnv = sin(pi * (leadLocal / leadStep).clamp(0, 1)) *
        (0.78 + 0.22 * sin(2 * pi * 5.5 * leadLocal));
    final lead = leadMix *
        leadEnv *
        synth(
          leadLocal,
          leadFreq + sin(2 * pi * 5.5 * leadLocal) * 2.1,
          brightness: 1.25,
        );

    final kickVoice = kick(beatLocal, accent: beatInBar == 0);
    final clap = (beatInBar == 1 || beatInBar == 3) && beatLocal < 0.22
        ? 0.055 *
            sin(pi * (beatLocal / 0.016).clamp(0.0, 1.0)) *
            exp(-beatLocal * 19) *
            digitalNoise(beatLocal)
        : 0.0;
    final hatStep = beat / 2;
    final hatLocal = t - (t / hatStep).floor() * hatStep;
    final hatEnv =
        sin(pi * (hatLocal / 0.010).clamp(0.0, 1.0)) * exp(-hatLocal * 34);
    final hat = 0.016 * shimmer * hatEnv * digitalNoise(hatLocal);

    return (pad + bass + arp + lead + kickVoice + clap + hat)
        .clamp(-0.84, 0.84);
  });
}

List<double> menuNeonDawn() => _cyberLoop(
      progression: const [
        [-9, -2, 3, 7],
        [-4, 0, 5, 9],
        [-7, -2, 2, 7],
        [-5, 0, 4, 9],
      ],
      melody: const [0, 3, 7, 10, 7, 3],
      bpm: 120,
      duration: 16,
      rootShift: 0,
      bassMix: 0.115,
      arpMix: 0.052,
      leadMix: 0.046,
      shimmer: 0.70,
    );

List<double> menuSkylineDrive() => _cyberLoop(
      progression: const [
        [-12, -5, 0, 4],
        [-10, -3, 2, 5],
        [-8, -1, 3, 7],
        [-13, -6, -1, 3],
      ],
      melody: const [4, 7, 9, 12, 9, 7],
      bpm: 135,
      duration: 16,
      rootShift: 1,
      bassMix: 0.125,
      arpMix: 0.060,
      leadMix: 0.042,
      shimmer: 0.92,
    );

List<double> menuCrystalArcade() => _cyberLoop(
      progression: const [
        [-7, -2, 2, 5],
        [-2, 2, 5, 9],
        [-9, -4, 0, 4],
        [-5, 0, 3, 7],
      ],
      melody: const [7, 11, 14, 16, 14, 11],
      bpm: 120,
      duration: 16,
      rootShift: -1,
      bassMix: 0.108,
      arpMix: 0.068,
      leadMix: 0.054,
      shimmer: 1.05,
    );

List<double> menuOrbitLounge() => _cyberLoop(
      progression: const [
        [-14, -9, -5, 0],
        [-12, -7, -3, 2],
        [-16, -11, -7, -2],
        [-10, -5, -1, 4],
      ],
      melody: const [0, 2, 5, 9, 5, 2],
      bpm: 120,
      duration: 16,
      rootShift: 2,
      bassMix: 0.104,
      arpMix: 0.050,
      leadMix: 0.050,
      shimmer: 0.76,
    );

List<double> gameGridRunner() => _cyberLoop(
      progression: const [
        [-16, -9, -4, 0],
        [-14, -7, -2, 2],
        [-11, -4, 0, 5],
        [-13, -6, -1, 3],
      ],
      melody: const [12, 15, 19, 22, 19, 15],
      bpm: 150,
      duration: 16,
      rootShift: 0,
      bassMix: 0.148,
      arpMix: 0.082,
      leadMix: 0.043,
      shimmer: 1.10,
    );

List<double> gameQuantumChase() => _cyberLoop(
      progression: const [
        [-12, -5, -1, 2],
        [-8, -1, 3, 6],
        [-10, -3, 1, 4],
        [-15, -8, -4, 0],
      ],
      melody: const [7, 10, 14, 17, 14, 10],
      bpm: 165,
      duration: 16,
      rootShift: 0,
      bassMix: 0.158,
      arpMix: 0.090,
      leadMix: 0.050,
      shimmer: 1.28,
    );

List<double> gameVoidRush() => _cyberLoop(
      progression: const [
        [-18, -11, -6, -2],
        [-15, -8, -3, 1],
        [-13, -6, -1, 3],
        [-20, -13, -8, -4],
      ],
      melody: const [3, 6, 10, 13, 10, 6],
      bpm: 165,
      duration: 16,
      rootShift: -1,
      bassMix: 0.168,
      arpMix: 0.094,
      leadMix: 0.040,
      shimmer: 1.42,
    );

List<double> gameStarlightSprint() => _cyberLoop(
      progression: const [
        [-9, -4, 0, 5],
        [-6, -1, 3, 8],
        [-11, -6, -2, 3],
        [-4, 1, 5, 10],
      ],
      melody: const [10, 14, 17, 21, 17, 14],
      bpm: 150,
      duration: 16,
      rootShift: 1,
      bassMix: 0.142,
      arpMix: 0.098,
      leadMix: 0.054,
      shimmer: 1.32,
    );

Future<void> main() async {
  final dir = Directory('assets/audio');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final files = {
    'button_click.wav': buttonClick(),
    'tap.wav': tap(),
    'coin.wav': coin(),
    'character_unlock.wav': characterUnlock(),
    'purchase_success.wav': purchaseSuccess(),
    'reward_received.wav': rewardReceived(),
    'game_over.wav': gameOver(),
    'countdown.wav': countdown(),
    'victory.wav': victory(),
    'music/menu_neon_dawn.wav': menuNeonDawn(),
    'music/menu_skyline_drive.wav': menuSkylineDrive(),
    'music/menu_crystal_arcade.wav': menuCrystalArcade(),
    'music/menu_orbit_lounge.wav': menuOrbitLounge(),
    'music/game_grid_runner.wav': gameGridRunner(),
    'music/game_quantum_chase.wav': gameQuantumChase(),
    'music/game_void_rush.wav': gameVoidRush(),
    'music/game_starlight_sprint.wav': gameStarlightSprint(),
  };

  for (final entry in files.entries) {
    final bytes = encodeWav(entry.value);
    final file = File('assets/audio/${entry.key}');
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes);
    print(
        'Wrote ${entry.key} (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
  }
  print('Audio generation complete.');
}
