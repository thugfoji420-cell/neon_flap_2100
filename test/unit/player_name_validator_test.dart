import 'package:flutter_test/flutter_test.dart';

import 'package:neon_flap1_game/firebase/player_name_validator.dart';

void main() {
  late PlayerNameValidator validator;

  setUp(() {
    validator = PlayerNameValidator();
  });

  group('PlayerNameValidator', () {
    group('validate', () {
      test('returns error for empty string', () {
        expect(validator.validate(''), equals('Enter a player name'));
      });

      test('returns error for whitespace only', () {
        expect(validator.validate('   '), equals('Enter a player name'));
      });

      test('returns error for name shorter than 4 characters', () {
        expect(validator.validate('abc'), equals('Use at least 4 characters'));
      });

      test('returns error for name longer than 16 characters', () {
        expect(
          validator.validate('a' * 17),
          equals('Max 16 characters'),
        );
      });

      test('returns null for valid name', () {
        expect(validator.validate('TestPlayer'), isNull);
      });

      test('returns null for name with exactly 4 characters', () {
        expect(validator.validate('Test'), isNull);
      });

      test('returns null for name with exactly 16 characters', () {
        expect(validator.validate('a' * 16), isNull);
      });

      test('returns error for name with spaces', () {
        expect(validator.validate('Test Player'), equals('No spaces allowed'));
      });

      test('returns error for name with special characters', () {
        expect(
          validator.validate('Test@Player'),
          equals('Letters, numbers and _ only'),
        );
      });

      test('returns error for name with emojis - fails regex first', () {
        // Emojis fail the regex check (^[a-zA-Z0-9_]+$) before the emoji check
        expect(
          validator.validate('Test🎮Player'),
          equals('Letters, numbers and _ only'),
        );
      });

      test('accepts name with underscore', () {
        expect(validator.validate('Test_Player'), isNull);
      });

      test('accepts name with numbers', () {
        expect(validator.validate('Player123'), isNull);
      });

      test('returns error for blocked word "admin"', () {
        expect(
          validator.validate('admin'),
          equals('This player name is not allowed'),
        );
      });

      test('returns error for blocked word case insensitive', () {
        expect(
          validator.validate('Admin'),
          equals('This player name is not allowed'),
        );
      });

      test('returns error for blocked word "root"', () {
        expect(
          validator.validate('root'),
          equals('This player name is not allowed'),
        );
      });

      test('returns error for blocked word "moderator"', () {
        expect(
          validator.validate('moderator'),
          equals('This player name is not allowed'),
        );
      });

      test('returns error for blocked word containing offensive term', () {
        expect(
          validator.validate('fuckboi'),
          equals('This player name is not allowed'),
        );
      });
    });

    group('toLookupKey', () {
      test('converts to lowercase', () {
        expect(validator.toLookupKey('TestPlayer'), equals('testplayer'));
      });

      test('trims whitespace', () {
        expect(validator.toLookupKey('  Test  '), equals('test'));
      });

      test('handles already lowercase', () {
        expect(validator.toLookupKey('testplayer'), equals('testplayer'));
      });
    });
  });
}
