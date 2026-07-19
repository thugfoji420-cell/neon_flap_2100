import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralised typed access to every top-level Firestore collection used by the
/// game. Keeping the collection names in one place avoids typos and makes the
/// data model easy to reason about.
///
/// Layout (document id == Firebase UID for every per-player collection):
///
///   players        - profile (username, coins, highScore, stats, ...)
///   usernames      - uniqueness index: usernames/{lower} -> {uid, createdAt}
///   leaderboard    - global best score per player
///   achievements   - unlocked achievement flags per player
///   inventory      - owned/selected characters (birds) per player
///   daily_rewards  - daily reward streak state per player
///   settings       - audio / vibration / language per player
///   cloud_save     - lightweight cloud save snapshot per player
///
/// Weekly / monthly leaderboards reuse the same document-per-player pattern but
/// carry a `periodId` field so an indexed query can return the current period.
class FirebaseRefs {
  FirebaseRefs(this.db);

  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get players =>
      db.collection('players');

  /// Uniqueness index. Document id == lowercased username.
  CollectionReference<Map<String, dynamic>> get usernames =>
      db.collection('usernames');

  CollectionReference<Map<String, dynamic>> get leaderboard =>
      db.collection('leaderboard');

  CollectionReference<Map<String, dynamic>> get leaderboardWeekly =>
      db.collection('leaderboard_weekly');

  CollectionReference<Map<String, dynamic>> get leaderboardMonthly =>
      db.collection('leaderboard_monthly');

  CollectionReference<Map<String, dynamic>> get achievements =>
      db.collection('achievements');

  CollectionReference<Map<String, dynamic>> get inventory =>
      db.collection('inventory');

  CollectionReference<Map<String, dynamic>> get dailyRewards =>
      db.collection('daily_rewards');

  CollectionReference<Map<String, dynamic>> get settings =>
      db.collection('settings');

  CollectionReference<Map<String, dynamic>> get cloudSave =>
      db.collection('cloud_save');

  DocumentReference<Map<String, dynamic>> player(String uid) =>
      players.doc(uid);
}
