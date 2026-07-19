import '../../domain/entities/public_player_profile.dart';

abstract class PublicProfileRepository {
  Future<PublicPlayerProfile?> getPublicProfile(String uid);
}
