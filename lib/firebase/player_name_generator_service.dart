import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neon_flap1_game/firebase/player_name_validator.dart';

/// Generates futuristic, cyber-themed player names and verifies their uniqueness
/// against Firestore before returning them.
class PlayerNameGeneratorService {
  PlayerNameGeneratorService({
    required FirebaseFirestore? firestore,
    PlayerNameValidator? validator,
  })  : _db = firestore,
        _validator = validator ?? PlayerNameValidator();

  final FirebaseFirestore? _db;
  final PlayerNameValidator _validator;

  static const _maxCandidates = 200;

  static const _prefixes = [
    'Neon',
    'Cyber',
    'Pixel',
    'Nova',
    'Quantum',
    'Ghost',
    'Turbo',
    'Iron',
    'Zero',
    'Hyper',
    'Vector',
    'Glitch',
    'Flux',
    'Chrome',
    'Data',
    'Grid',
    'Void',
    'Echo',
    'Prism',
    'Volt',
    'Static',
    'Nexus',
    'Cipher',
    'Shard',
    'Surge',
    'Core',
    'Pulse',
    'Rogue',
    'Blitz',
    'Aether',
    'Binary',
    'Circuit',
    'Delta',
    'Omega',
    'Sigma',
    'Titan',
    'Vortex',
    'Zenith',
    'Nebula',
    'Orbit',
    'Photon',
    'Quasar',
    'Radial',
    'Synth',
    'Tensor',
    'Ultra',
    'Warp',
    'Zen',
    'Arc',
    'Node',
  ];

  static const _suffixes = [
    'Falcon',
    'Raven',
    'Storm',
    'Pilot',
    'Fox',
    'Wing',
    'Volt',
    'Phoenix',
    'Wolf',
    'Gravity',
    'Blade',
    'Viper',
    'Spectre',
    'Hawk',
    'Rider',
    'Hunter',
    'Phantom',
    'Drifter',
    'Cipher',
    'Shard',
    'Surge',
    'Core',
    'Pulse',
    'Blitz',
    'Aether',
    'Circuit',
    'Delta',
    'Omega',
    'Sigma',
    'Titan',
    'Vortex',
    'Zenith',
    'Nebula',
    'Orbit',
    'Photon',
    'Quasar',
    'Synth',
    'Tensor',
    'Warp',
    'Node',
    'Striker',
    'Reaper',
    'Sentinel',
    'Vanguard',
    'Ranger',
    'Maverick',
    'Shadow',
    'Mirage',
    'Echo',
    'Forge',
  ];

  static const _endings = [
    '',
    '_x',
    '_zero',
    '_v',
    '_neo',
    '_ex',
    '_prime',
    '_01',
    '_7',
    '_99',
    '_88',
    '_13',
  ];

  /// Generates a single random username without network checks.
  String generateRaw() {
    final r = Random();
    final prefix = _prefixes[r.nextInt(_prefixes.length)];
    final suffix = _suffixes[r.nextInt(_suffixes.length)];
    final ending = _endings[r.nextInt(_endings.length)];

    final patterns = <String Function()>[
      () => '$prefix$suffix$ending',
      () => '$prefix$suffix',
      () => '$suffix$prefix',
      () => '$prefix$ending',
      () => '$prefix${suffix.substring(0, 1)}$ending',
      () => '$suffix$ending',
      () => '$prefix${suffix.substring(0, min(4, suffix.length))}',
    ];

    var candidate = patterns[r.nextInt(patterns.length)]();
    if (candidate.length > PlayerNameValidator.maxLength) {
      candidate = candidate.substring(0, PlayerNameValidator.maxLength);
    }
    return candidate;
  }

  /// Generates a batch of unique candidate usernames.
  List<String> generateCandidates({int count = _maxCandidates}) {
    final r = Random();
    final seen = <String>{};
    final result = <String>[];

    while (result.length < count && seen.length < _maxCandidates) {
      final prefix = _prefixes[r.nextInt(_prefixes.length)];
      final suffix = _suffixes[r.nextInt(_suffixes.length)];
      final ending = _endings[r.nextInt(_endings.length)];

      final patterns = <String Function()>[
        () => '$prefix$suffix$ending',
        () => '$prefix$suffix',
        () => '$suffix$prefix',
        () => '$prefix$ending',
        () => '$prefix${suffix.substring(0, min(4, suffix.length))}$ending',
        () => '$suffix$ending',
        () => '$prefix${suffix.substring(0, min(3, suffix.length))}',
        () => '$prefix$suffix${r.nextInt(99)}',
      ];

      var candidate = patterns[r.nextInt(patterns.length)]();
      if (candidate.length > PlayerNameValidator.maxLength) {
        candidate = candidate.substring(0, PlayerNameValidator.maxLength);
      }

      final error = _validator.validate(candidate);
      if (error != null) continue;

      final key = candidate.toLowerCase();
      if (seen.add(key)) {
        result.add(candidate);
      }
    }

    return result;
  }

  /// Returns the first available username from a generated batch by checking
  /// Firestore. If none are available, returns null.
  Future<String?> findAvailable({int attempts = _maxCandidates}) async {
    final candidates = generateCandidates(count: attempts);

    for (final candidate in candidates) {
      if (await _isAvailable(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  /// Returns true when [value] passes local validation and is not present in
  /// the Firestore `usernames` collection.
  Future<bool> _isAvailable(String value) async {
    final error = _validator.validate(value);
    if (error != null) return false;

    final db = _db;
    if (db == null) return true;

    final lower = _validator.toLookupKey(value);
    try {
      final doc = await db.collection('usernames').doc(lower).get();
      return !doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Generates and claims an available username for [uid] in one atomic flow.
  /// Returns the claimed username, or null if none could be found/claimed.
  Future<String?> generateAndClaim(String uid) async {
    final db = _db;
    if (db == null) return null;
    final candidates = generateCandidates(count: _maxCandidates);

    for (final candidate in candidates) {
      final error = _validator.validate(candidate);
      if (error != null) continue;

      final lower = _validator.toLookupKey(candidate);
      try {
        final doc = await db.collection('usernames').doc(lower).get();
        if (doc.exists) continue;

        final batch = db.batch();
        batch.set(
          db.collection('usernames').doc(lower),
          {'uid': uid, 'createdAt': FieldValue.serverTimestamp()},
        );
        batch.set(
          db.collection('players').doc(uid),
          {
            'username': candidate.trim(),
            'usernameLower': lower,
            'lastLogin': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        await batch.commit();
        return candidate;
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  /// Returns the total theoretical combination count (informational only).
  int get theoreticalCombinations =>
      _prefixes.length * _suffixes.length * _endings.length;
}
