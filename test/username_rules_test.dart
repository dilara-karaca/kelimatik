import 'package:flutter_test/flutter_test.dart';

import 'package:kelimatik/core/constants/app_characters.dart';

void main() {
  group('UsernameRules.validate', () {
    test('accepts lowercase alphanumeric', () {
      expect(UsernameRules.validate('anil'), isNull);
      expect(UsernameRules.validate('anil123'), isNull);
      expect(UsernameRules.validate('anilguler'), isNull);
      expect(UsernameRules.validate('123anil'), isNull);
    });

    test('accepts punctuation and special characters', () {
      expect(UsernameRules.validate('anil.guler'), isNull);
      expect(UsernameRules.validate('anil_guler'), isNull);
      expect(UsernameRules.validate('anil-guler'), isNull);
      expect(UsernameRules.validate('anil!'), isNull);
      expect(UsernameRules.validate('anil.123'), isNull);
      expect(UsernameRules.validate('anil_123'), isNull);
      expect(UsernameRules.validate('anil?ok'), isNull);
      expect(UsernameRules.validate('a,b,c'), isNull);
    });

    test('rejects uppercase without auto-lowercase', () {
      expect(UsernameRules.validate('Anil'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('ANIL'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('Çağrı'), UsernameRules.invalidCharsetMessage);
    });

    test('rejects turkish letters emoji spaces', () {
      expect(UsernameRules.validate('anıl'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('şahin'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('ömer'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('anil guler'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('anil😀'), UsernameRules.invalidCharsetMessage);
    });

    test('rejects empty and short/long', () {
      expect(UsernameRules.validate(''), UsernameRules.invalidLengthMessage);
      expect(UsernameRules.validate('ab'), UsernameRules.invalidLengthMessage);
      expect(
        UsernameRules.validate('a' * 21),
        UsernameRules.invalidLengthMessage,
      );
    });
  });
}
