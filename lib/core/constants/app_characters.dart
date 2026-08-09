/// Character ids and asset paths under `assets/characters/`.
abstract final class AppCharacters {
  static const String _base = 'assets/characters';

  static const List<String> ids = [
    'erkek1',
    'erkek2',
    'erkek3',
    'erkek4',
    'erkek5',
    'kadin1',
    'kadin2',
    'kadin3',
    'kadin4',
    'kadin5',
  ];

  static String assetFor(String id) => '$_base/$id.png';

  static bool isValidId(String id) => ids.contains(id);
}

/// Username rules for onboarding (exact match — no auto-lowercase).
abstract final class UsernameRules {
  static const int minLength = 3;
  static const int maxLength = 20;
  static final RegExp pattern = RegExp(r'^[a-z0-9]+$');

  static const String invalidCharsetMessage =
      'Kullanıcı adı sadece küçük harf ve rakamlardan oluşabilir.';
  static const String invalidLengthMessage =
      'Kullanıcı adı $minLength–$maxLength karakter olmalı.';
  static const String takenMessage = 'Bu kullanıcı adı zaten kullanılıyor.';

  /// Returns an error message, or null if [value] is valid.
  static String? validate(String value) {
    if (value.length < minLength || value.length > maxLength) {
      return invalidLengthMessage;
    }
    if (!pattern.hasMatch(value)) {
      return invalidCharsetMessage;
    }
    return null;
  }
}
