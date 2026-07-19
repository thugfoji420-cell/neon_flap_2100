import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/firebase/player_name_service.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

/// "Change Player Name" dialog used from Settings. Verifies uniqueness, rewrites
/// the profile + uniqueness index via a transactional write (handled by
/// [PlayerNameService]), and reports inline errors.
Future<void> showChangePlayerNameDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ChangePlayerNameDialog(),
  );
}

class _ChangePlayerNameDialog extends StatefulWidget {
  const _ChangePlayerNameDialog();

  @override
  State<_ChangePlayerNameDialog> createState() =>
      _ChangePlayerNameDialogState();
}

class _ChangePlayerNameDialogState extends State<_ChangePlayerNameDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final firebase = sl<FirebaseService>();
    final uid = firebase.uid;
    if (uid == null) {
      setState(() {
        _saving = false;
        _error = 'Network error. Please retry.';
      });
      return;
    }

    final result = await firebase.setPlayerName(_controller.text);
    if (!mounted) return;

    switch (result) {
      case PlayerNameResult.success:
        if (mounted) Navigator.of(context).pop();
        return;
      case PlayerNameResult.taken:
        setState(() {
          _saving = false;
          _error = 'This player name is already taken.';
        });
        break;
      case PlayerNameResult.invalid:
        setState(() {
          _saving = false;
          _error = 'Invalid player name.';
        });
        break;
      case PlayerNameResult.error:
        setState(() {
          _saving = false;
          _error = 'Network error. Please retry.';
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebase = sl<FirebaseService>();
    final scheme = Theme.of(context).colorScheme;
    final errorMsg = _error;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: NeonPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CHANGE PLAYER NAME', style: NeonTextStyle.heading),
            const SizedBox(height: 8),
            Text(
              'Current: ${firebase.playerName}',
              style: NeonTextStyle.label,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                autofocus: true,
                enabled: !_saving,
                maxLength: 16,
                textCapitalization: TextCapitalization.none,
                style: NeonTextStyle.heading.copyWith(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'new_player_name',
                  hintStyle: NeonTextStyle.label,
                  filled: true,
                  fillColor: NeonTheme.colors(context).field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.error),
                  ),
                  counterStyle: NeonTextStyle.label,
                ),
                validator: (v) =>
                    firebase.playerNameService.validateFormat(v ?? ''),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onFieldSubmitted: (_) => _save(),
              ),
            ),
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMsg,
                  style: NeonTextStyle.body.copyWith(color: scheme.error),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'CANCEL',
                    color: NeonPalette.red,
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeonButton(
                    label: _saving ? 'SAVING...' : 'SAVE',
                    color: NeonPalette.green,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
