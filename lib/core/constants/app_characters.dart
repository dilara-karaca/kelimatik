/// Character ids and asset paths under `assets/characters/`.
abstract final class AppCharacters {
  static const String _base = 'assets/characters';

  /// Neutral placeholder shown first; not a savable character.
  static const String placeholderId = 'user';

  static const List<String> maleIds = [
    'erkek1',
    'erkek2',
    'erkek3',
    'erkek4',
    'erkek5',
  ];

  static const List<String> femaleIds = [
    'kadin1',
    'kadin2',
    'kadin3',
    'kadin4',
    'kadin5',
  ];

  /// Selectable characters that may be stored on the profile.
  static const List<String> ids = [
    ...maleIds,
    ...femaleIds,
  ];

  /// Carousel order: males on the left → [user] center → females on the right.
  static const List<String> carouselIds = [
    ...maleIds,
    placeholderId,
    ...femaleIds,
  ];

  /// Index of [placeholderId] in [carouselIds] — initial onboarding selection.
  static const int initialCarouselIndex = 5;

  static String assetFor(String id) => '$_base/$id.png';

  static bool isValidId(String id) => ids.contains(id);

  static bool isPlaceholder(String id) => id == placeholderId;

  /// Placeholder is a filled square silhouette; full-body art is taller and
  /// visually smaller in the same slot — scale placeholder down to match.
  static double displayScaleFor(String id) => isPlaceholder(id) ? 0.58 : 1.0;

  /// Extra downward shift (fraction of carousel height) so the bust silhouette
  /// lines up with full-body character art when centered.
  static double displayYOffsetFor(String id) => isPlaceholder(id) ? 0.055 : 0.0;
}

/// Username rules for onboarding (exact match — no auto-lowercase).
abstract final class UsernameRules {
  static const int minLength = 3;
  static const int maxLength = 20;

  /// Lowercase a-z, digits, and ASCII punctuation/symbols only.
  /// Rejects A-Z, Turkish letters, emoji, and other non-ASCII.
  static final RegExp pattern = RegExp(
    r'''^[a-z0-9!"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~]+$''',
  );

  static const String invalidCharsetMessage =
      'Kullanıcı adı küçük harf, rakam ve noktalama içerebilir; büyük harf, Türkçe karakter ve emoji kullanılamaz.';
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
