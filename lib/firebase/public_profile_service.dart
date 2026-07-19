import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neon_flap1_game/domain/entities/public_player_profile.dart';
import 'package:neon_flap1_game/domain/repositories/public_profile_repository.dart';
import 'package:neon_flap1_game/data/repositories/public_profile_repository_impl.dart';

/// Fetches and caches public player profiles for leaderboard and social screens.
class PublicProfileService {
  PublicProfileService(this._db);

  final FirebaseFirestore _db;
  late final PublicProfileRepository _repository =
      PublicProfileRepositoryImpl(_db);

  final Map<String, PublicPlayerProfile> _cache = {};

  Future<PublicPlayerProfile?> getProfile(String uid) async {
    if (_cache.containsKey(uid)) return _cache[uid];

    final profile = await _repository.getPublicProfile(uid);
    if (profile != null) {
      _cache[uid] = profile;
    }
    return profile;
  }

  void evict(String uid) {
    _cache.remove(uid);
  }

  void clearCache() {
    _cache.clear();
  }
}
