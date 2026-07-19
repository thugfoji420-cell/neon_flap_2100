/// Words that are never allowed as a player name (case-insensitive, stripped of
/// separators before comparison).
const Set<String> _defaultBlockedWords = {
  'admin',
  'root',
  'moderator',
  'support',
  'official',
  'fuck',
  'shit',
  'bitch',
  'ass',
  'bastard',
  'damn',
  'cunt',
  'slut',
  'whore',
  'nigger',
  'fag',
  'retard',
  'idiot',
  'scam',
  'hacker',
  'cheater',
  'neo_nazi',
  'nazi',
  'hitler',
  'porn',
  'sex',
  'dick',
  'pussy',
  'penis',
  'vagina',
};

/// Pure validation logic for player names. No Firebase / Flutter deps so it
/// is trivially testable and can be reused by the UI and the service layer.
///
/// Rules (per spec):
///   - length 4 to 16 characters
///   - letters A-Z, numbers 0-9 and underscore only
///   - no spaces, no special symbols, no emojis
///   - stored lowercase for uniqueness; displayed with original capitalization
class PlayerNameValidator {
  PlayerNameValidator({this.blockedWords = _defaultBlockedWords});

  /// Words that are never allowed as a player name.
  final Set<String> blockedWords;

  static const int minLength = 4;
  static const int maxLength = 16;

  /// [value] is already validated text. Returns null when valid, otherwise a
  /// user-facing error message.
  String? validate(String value) {
    final raw = value.trim();

    if (raw.isEmpty) return 'Enter a player name';
    if (raw.length < minLength) return 'Use at least $minLength characters';
    if (raw.length > maxLength) return 'Max $maxLength characters';

    // No whitespace of any kind.
    if (raw.contains(RegExp(r'\s'))) return 'No spaces allowed';

    // Letters, numbers and underscore only. The unicode range rejects emojis
    // and any accented/non-latin glyphs.
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(raw)) {
      return 'Letters, numbers and _ only';
    }

    // Detect emojis / pictographs that slipped past the regex (e.g. combined).
    if (_containsEmoji(raw)) return 'Emojis are not allowed';

    // Offensive-word filter: compare against the lowercased, separator-free form.
    final normalized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final word in blockedWords) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (clean.isNotEmpty && normalized.contains(clean)) {
        return 'This player name is not allowed';
      }
    }

    return null;
  }

  /// Lowercase form used as the Firestore document id for uniqueness checks.
  String toLookupKey(String value) => value.trim().toLowerCase();

  bool _containsEmoji(String value) {
    return value.runes.any((r) {
      // Covers the major emoji planes / variation selectors.
      return (r >= 0x1F000 && r <= 0x1FAFF) ||
          (r >= 0x2600 && r <= 0x27BF) ||
          (r >= 0xFE00 && r <= 0xFE0F) ||
          (r >= 0x1F1E6 && r <= 0x1F1FF) ||
          (r >= 0x2190 && r <= 0x21FF);
    });
  }
}
