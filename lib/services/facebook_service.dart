import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;

import 'package:neon_flap_2100/core/constants/app_constants.dart';
import 'package:neon_flap_2100/services/storage_service.dart';

class FacebookUser {
  const FacebookUser({
    required this.id,
    required this.name,
    this.email,
    this.accessToken,
  });

  final String id;
  final String name;
  final String? email;
  final String? accessToken;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'accessToken': accessToken,
      };

  factory FacebookUser.fromJson(Map<String, dynamic> json) => FacebookUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        accessToken: json['accessToken'] as String?,
      );
}

class FacebookService extends ChangeNotifier {
  FacebookService(this._storage);

  final StorageService _storage;

  FacebookUser? _user;
  FacebookUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    await _loadUser();
  }

  Future<void> _loadUser() async {
    final id = _storage.getString(StorageKeys.facebookUserId);
    final name = _storage.getString(StorageKeys.facebookUserName);
    final email = _storage.getString(StorageKeys.facebookUserEmail);
    final token = _storage.getString(StorageKeys.facebookAccessToken);

    if (id != null && name != null) {
      _user = FacebookUser(
        id: id,
        name: name,
        email: email,
        accessToken: token,
      );
      notifyListeners();
    }
  }

  Future<bool> login() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email', 'user_friends'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'id,name,email',
        );

        final accessToken = result.accessToken?.tokenString;

        _user = FacebookUser(
          id: userData['id'] as String,
          name: userData['name'] as String,
          email: userData['email'] as String?,
          accessToken: accessToken,
        );

        await _saveUser();
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await FacebookAuth.instance.logOut();
    await _clearUser();
    notifyListeners();
  }

  Future<void> _saveUser() async {
    if (_user == null) return;
    await _storage.setString(StorageKeys.facebookUserId, _user!.id);
    await _storage.setString(StorageKeys.facebookUserName, _user!.name);
    if (_user!.email != null) {
      await _storage.setString(StorageKeys.facebookUserEmail, _user!.email!);
    }
    if (_user!.accessToken != null) {
      await _storage.setString(
        StorageKeys.facebookAccessToken,
        _user!.accessToken!,
      );
    }
  }

  Future<void> _clearUser() async {
    _user = null;
    await _storage.remove(StorageKeys.facebookUserId);
    await _storage.remove(StorageKeys.facebookUserName);
    await _storage.remove(StorageKeys.facebookUserEmail);
    await _storage.remove(StorageKeys.facebookAccessToken);
    await _storage.remove(StorageKeys.facebookSyncTimestamp);
  }

  Future<String?> syncGameData(String gameDataJson) async {
    if (_user?.accessToken == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _storage.setString(
        StorageKeys.facebookSyncTimestamp,
        timestamp.toString(),
      );

      final response = await http.post(
        Uri.https('graph.facebook.com', '/v18.0/me/neon_flap_2100_backup'),
        body: {
          'backup_data': gameDataJson,
          'sync_timestamp': timestamp.toString(),
          'access_token': _user!.accessToken!,
        },
      );

      if (response.statusCode == 200) {
        return _user!.id;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> restoreGameData() async {
    if (_user?.accessToken == null) return null;

    try {
      final response = await http.get(
        Uri.https('graph.facebook.com', '/v18.0/me/neon_flap_2100_backup', {
          'access_token': _user!.accessToken!,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('backup_data')) {
          final backup = data['backup_data'] as String;
          return jsonDecode(backup) as Map<String, dynamic>;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFacebookFriendsScores() async {
    if (_user?.accessToken == null) return const [];

    try {
      final response = await http.get(
        Uri.https('graph.facebook.com', '/v18.0/me/friends', {
          'fields': 'id,name,picture',
          'access_token': _user!.accessToken!,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('data')) {
          final friends = data['data'] as List;
          return friends.map((f) {
            final map = f as Map<String, dynamic>;
            return {
              'id': map['id'] as String,
              'name': map['name'] as String? ?? 'Unknown',
              'score': 0,
              'picture': map['picture'] != null
                  ? (map['picture'] as Map<String, dynamic>)['data']
                      ?.toString()
                  : null,
            };
          }).toList();
        }
      }

      return const [];
    } catch (e) {
      return const [];
    }
  }

  Future<void> postScoreToFacebook(int score, String difficulty) async {
    if (_user?.accessToken == null) return;

    try {
      await http.post(
        Uri.https('graph.facebook.com', '/v18.0/me/neon_flap_2100_scores'),
        body: {
          'score': score.toString(),
          'difficulty': difficulty,
          'access_token': _user!.accessToken!,
        },
      );
    } catch (e) {
      // Ignore score sync failures.
    }
  }
}
