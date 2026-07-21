import 'dart:async';

import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/legal/legal_document.dart';
import 'package:neon_flap1_game/routing/route_transitions.dart';
import 'package:neon_flap1_game/screens/google_sign_in_screen.dart';
import 'package:neon_flap1_game/services/offline_profile_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/holo_panel.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  bool get _isDataDeletion => document.id == 'data_deletion';

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: NeonTextStyle.heading),
        content: Text(message, style: NeonTextStyle.body),
        actions: [
          SizedBox(
            width: 112,
            child: NeonButton(
              label: 'CANCEL',
              height: 42,
              fontSize: 12,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
          ),
          SizedBox(
            width: 150,
            child: NeonButton(
              label: actionLabel,
              color: NeonPalette.red,
              height: 42,
              fontSize: 12,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _showBusy(BuildContext context, String label) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: HoloPanel(
          color: NeonPalette.cyan,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: NeonPalette.cyan),
              const SizedBox(height: 14),
              Text(label, style: NeonTextStyle.label),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLocalGuestData(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Delete Local Guest Data?',
      message:
          'This removes offline guest progress saved on this device. It does not delete a Google account or cloud progress.',
      actionLabel: 'DELETE',
    );
    if (!ok || !context.mounted) return;

    unawaited(_showBusy(context, 'DELETING LOCAL DATA...'));
    await Future<void>.delayed(Duration.zero);
    final firebase = sl<FirebaseService>();
    if (firebase.isOfflineGuest || !firebase.isSignedIn) {
      await firebase.deleteOfflineProfile();
    } else {
      await sl<OfflineProfileService>().deleteProfileOnly();
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (firebase.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local guest data deleted.')),
      );
    } else {
      replaceWithFade(context, const GoogleSignInScreen());
    }
  }

  Future<void> _deleteCloudAccount(BuildContext context) async {
    final firebase = sl<FirebaseService>();
    if (!firebase.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with Google to delete cloud account data.'),
        ),
      );
      return;
    }

    final ok = await _confirm(
      context,
      title: 'Delete Account and Cloud Data?',
      message:
          'This permanently deletes your Google-linked Neon Flap 2100 cloud data and account access. This cannot be undone.',
      actionLabel: 'DELETE',
    );
    if (!ok || !context.mounted) return;

    unawaited(_showBusy(context, 'DELETING CLOUD DATA...'));
    await Future<void>.delayed(Duration.zero);
    final error = await firebase.deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (error != null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete Failed', style: NeonTextStyle.heading),
          content: Text(error, style: NeonTextStyle.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK', style: NeonTextStyle.label),
            ),
          ],
        ),
      );
      return;
    }
    replaceWithFade(context, const GoogleSignInScreen());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.cyan,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: NeonLayout.screenPadding(context).copyWith(
              top: 24,
              bottom: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: HoloPanel(
                  color: NeonPalette.cyan,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document.title, style: NeonTextStyle.heading),
                      const SizedBox(height: 6),
                      Text(
                        'Last updated: ${document.lastUpdated}',
                        style: NeonTextStyle.label.copyWith(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final section in document.sections) ...[
                        Text(
                          section.heading,
                          style: NeonTextStyle.label.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(section.body, style: NeonTextStyle.body),
                        const SizedBox(height: 18),
                      ],
                      if (_isDataDeletion) ...[
                        const Divider(),
                        const SizedBox(height: 14),
                        NeonButton(
                          label: 'DELETE LOCAL GUEST DATA',
                          icon: Icons.delete_sweep_outlined,
                          color: NeonPalette.red,
                          fontSize: 12,
                          onPressed: () => _deleteLocalGuestData(context),
                        ),
                        const SizedBox(height: 12),
                        NeonButton(
                          label: 'DELETE ACCOUNT AND CLOUD DATA',
                          icon: Icons.cloud_off_outlined,
                          color: NeonPalette.red,
                          fontSize: 12,
                          onPressed: () => _deleteCloudAccount(context),
                        ),
                        const SizedBox(height: 18),
                      ],
                      Center(
                        child: NeonBackButton(
                          label: 'BACK',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
