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

    test('rejects uppercase without auto-lowercase', () {
      expect(UsernameRules.validate('Anil'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('ANIL'), UsernameRules.invalidCharsetMessage);
    });

    test('rejects turkish letters and separators', () {
      expect(UsernameRules.validate('anıl'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('şahin'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('anil_guler'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('anil-guler'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('anil.guler'), UsernameRules.invalidCharsetMessage);
      expect(UsernameRules.validate('anil guler'), UsernameRules.invalidCharsetMessage);
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
