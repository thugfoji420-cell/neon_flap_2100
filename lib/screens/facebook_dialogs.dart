import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/services/facebook_service.dart';
import 'package:neon_flap_2100/widgets/neon_button.dart';

Future<void> showFacebookLoginDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return _FacebookLoginDialog();
    },
  );
}

class _FacebookLoginDialog extends StatefulWidget {
  const _FacebookLoginDialog();

  @override
  State<_FacebookLoginDialog> createState() => _FacebookLoginDialogState();
}

class _FacebookLoginDialogState extends State<_FacebookLoginDialog> {
  bool _loading = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final facebook = sl<FacebookService>();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: NeonPalette.backgroundDark,
          border: Border.all(color: NeonPalette.cyan.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: NeonPalette.cyan.withOpacity(0.25),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              facebook.isLoggedIn ? 'FACEBOOK ACCOUNT' : 'LOGIN WITH FACEBOOK',
              style: NeonTextStyle.heading,
            ),
            const SizedBox(height: 18),
            if (facebook.isLoggedIn && facebook.user != null) ...[
              Text('Welcome, ${facebook.user!.name}',
                  style: NeonTextStyle.body),
              const SizedBox(height: 12),
              if (_message != null)
                Text(_message!, style: NeonTextStyle.label),
              const SizedBox(height: 12),
              NeonButton(
                label: 'SYNC DATA',
                color: NeonPalette.green,
                enabled: !_loading,
                onPressed: () => _syncData(context, facebook),
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: 'FRIENDS LEADERBOARD',
                color: NeonPalette.magenta,
                enabled: !_loading,
                onPressed: () => _showFriendsLeaderboard(context, facebook),
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: 'LOGOUT',
                color: NeonPalette.red,
                enabled: !_loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  await facebook.logout();
                  if (mounted) {
                    setState(() {
                      _loading = false;
                      _message = null;
                    });
                  }
                },
              ),
            ] else ...[
              const Text(
                'Connect with Facebook to save your progress and compete with friends.',
                style: NeonTextStyle.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              NeonButton(
                label: 'CONTINUE WITH FACEBOOK',
                color: const Color(0xFF1877F2),
                enabled: !_loading,
                onPressed: () => _login(context, facebook),
              ),
            ],
            const SizedBox(height: 12),
            NeonButton(
              label: 'CLOSE',
              color: NeonPalette.red,
              fontSize: 14,
              height: 40,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context, FacebookService facebook) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final success = await facebook.login();
    if (mounted) {
      setState(() => _loading = false);
      if (!success) {
        setState(() => _message = 'Login cancelled or failed.');
      }
    }
  }

  Future<void> _syncData(BuildContext context, FacebookService facebook) async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final Map<String, dynamic> backup = {};

    for (final key in allKeys) {
      final value = prefs.get(key);
      if (value is String) backup[key] = value;
      if (value is int) backup[key] = value;
      if (value is bool) backup[key] = value;
      if (value is double) backup[key] = value;
    }

    final encoded = jsonEncode(backup);
    final synced = await facebook.syncGameData(encoded);

    if (mounted) {
      setState(() {
        _loading = false;
        _message = synced != null ? 'Data synced successfully.' : 'Sync failed.';
      });
    }
  }

  Future<void> _showFriendsLeaderboard(
      BuildContext context, FacebookService facebook) async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final friends = await facebook.getFacebookFriendsScores();

    if (mounted) {
      setState(() => _loading = false);
      if (friends.isEmpty) {
        setState(() => _message = 'No Facebook friends found or permission denied.');
        return;
      }
      showDialog(
        context: context,
        builder: (_) => _FacebookFriendsLeaderboardDialog(friends: friends),
      );
    }
  }
}

class _FacebookFriendsLeaderboardDialog extends StatelessWidget {
  const _FacebookFriendsLeaderboardDialog({required this.friends});

  final List<Map<String, dynamic>> friends;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: NeonPalette.backgroundDark,
          border: Border.all(color: NeonPalette.cyan.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: NeonPalette.cyan.withOpacity(0.25),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('FACEBOOK FRIENDS', style: NeonTextStyle.heading),
                NeonButton(
                  label: 'CLOSE',
                  color: NeonPalette.red,
                  fontSize: 14,
                  height: 36,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (friends.isEmpty)
              const Text('No friends data available.', style: NeonTextStyle.body)
            else
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  child: Column(
                    children: friends.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: NeonPalette.cyan.withOpacity(0.35)),
                            color: NeonPalette.backgroundDark.withOpacity(0.7),
                          ),
                          child: Row(
                            children: [
                              Text(
                                (f['name'] as String?) ?? 'Unknown',
                                style: NeonTextStyle.heading.copyWith(
                                    fontSize: 16),
                              ),
                              const Spacer(),
                              Text('${f['score']} PTS',
                                  style: NeonTextStyle.label),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
