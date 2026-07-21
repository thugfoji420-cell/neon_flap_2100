import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/public_player_profile.dart';
import '../../domain/repositories/public_profile_repository.dart';
import '../models/public_profile_model.dart';

class PublicProfileRepositoryImpl implements PublicProfileRepository {
  PublicProfileRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Future<PublicPlayerProfile?> getPublicProfile(String uid) async {
    try {
      final playerDoc = await _db.collection('players').doc(uid).get();
      if (!playerDoc.exists) return null;

      final leaderboardDoc = await _db.collection('leaderboard').doc(uid).get();
      final achievementsDoc =
          await _db.collection('achievements').doc(uid).get();

      final model = PublicProfileModel.fromFirestore(
        uid,
        playerDoc.data() ?? {},
        leaderboardDoc.data() ?? {},
        achievementsDoc.data() ?? {},
      );

      final resolved = <PublicAchievement>[];
      for (final a in model.achievements) {
        final def = _lookupAchievement(a.id);
        if (def != null) {
          resolved.add(PublicAchievement(
            id: a.id,
            title: def['title'] as String,
            icon: def['icon'] as String,
            target: def['target'] as int,
            progress: a.claimed ? (def['target'] as int) : 0,
            claimed: a.claimed,
          ));
        }
      }

      return model.toEntity(resolved);
    } catch (_) {
      return null;
    }
  }

  static const _achievementDefs = <Map<String, dynamic>>[
    {'id': 'first_flight', 'title': 'First Flight', 'icon': '🚀', 'target': 1},
    {'id': 'high_flyer', 'title': 'High Flyer', 'icon': '🌟', 'target': 50},
    {'id': 'marathon', 'title': 'Marathon', 'icon': '🏆', 'target': 150},
    {
      'id': 'coin_collector',
      'title': 'Coin Collector',
      'icon': '🪙',
      'target': 100
    },
    {'id': 'veteran', 'title': 'Veteran', 'icon': '🎖️', 'target': 25},
    {'id': 'legend', 'title': 'Legend', 'icon': '👑', 'target': 500},
    {
      'id': 'bronze_flyer',
      'title': 'Bronze Flyer',
      'icon': '🥉',
      'target': 250
    },
    {
      'id': 'silver_collector',
      'title': 'Silver Collector',
      'icon': '🥈',
      'target': 500
    },
    {'id': 'bronze_gamer', 'title': 'Bronze Gamer', 'icon': '🎮', 'target': 50},
    {'id': 'gold_flyer', 'title': 'Gold Flyer', 'icon': '🥇', 'target': 1000},
    {
      'id': 'platinum_flyer',
      'title': 'Platinum Flyer',
      'icon': '💎',
      'target': 2500
    },
    {
      'id': 'gold_collector',
      'title': 'Gold Collector',
      'icon': '💰',
      'target': 2000
    },
    {
      'id': 'diamond_collector',
      'title': 'Diamond Collector',
      'icon': '🏅',
      'target': 10000
    },
    {
      'id': 'silver_gamer',
      'title': 'Silver Gamer',
      'icon': '🎯',
      'target': 100
    },
    {'id': 'gold_gamer', 'title': 'Gold Gamer', 'icon': '🏆', 'target': 500},
    {
      'id': 'platinum_gamer',
      'title': 'Platinum Gamer',
      'icon': '👑',
      'target': 1000
    },
    {
      'id': 'score_hoarder',
      'title': 'Score Hoarder',
      'icon': '📊',
      'target': 5000
    },
    {
      'id': 'score_tycoon',
      'title': 'Score Tycoon',
      'icon': '📈',
      'target': 50000
    },
    {
      'id': 'flap_apprentice',
      'title': 'Flap Apprentice',
      'icon': '🪽',
      'target': 500
    },
    {
      'id': 'flap_master',
      'title': 'Flap Master',
      'icon': '🕊️',
      'target': 5000
    },
    {
      'id': 'flap_legend',
      'title': 'Flap Legend',
      'icon': '🦅',
      'target': 50000
    },
    {'id': 'coin_rush', 'title': 'Coin Rush', 'icon': '💨', 'target': 50},
    {'id': 'coin_storm', 'title': 'Coin Storm', 'icon': '⛈️', 'target': 200},
    {
      'id': 'coin_typhoon',
      'title': 'Coin Typhoon',
      'icon': '🌪️',
      'target': 1000
    },
  ];

  static Map<String, dynamic>? _lookupAchievement(String id) {
    for (final def in _achievementDefs) {
      if (def['id'] == id) return def;
    }
    return null;
  }
}
