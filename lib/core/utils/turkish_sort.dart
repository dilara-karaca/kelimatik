/// Turkish alphabet: a b c ç d e f g ğ h ı i j k l m n o ö p r s ş t u ü v y z.
const _letters = 'abcçdefgğhıijklmnoöprsştuüvyz';

/// Compares [a] and [b] in Turkish alphabetical order, A to Z.
///
/// `ı` comes before `i`, and `ç ğ ö ş ü` sit right after their base letters.
/// A space sorts before any letter, so `bir an` comes before `biraz`.
int compareTurkish(String a, String b) {
  final left = _ranks(a);
  final right = _ranks(b);
  final length = left.length < right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final order = left[i].compareTo(right[i]);
    if (order != 0) return order;
  }
  return left.length.compareTo(right.length);
}

List<int> _ranks(String value) {
  final ranks = <int>[];
  for (final rune in value.runes) {
    ranks.add(_rank(rune));
  }
  return ranks;
}

int _rank(int rune) {
  if (rune == 0x20) return 0;

  final letter = switch (rune) {
    0x49 => 'ı', // I
    0x130 => 'i', // İ
    _ => String.fromCharCode(rune).toLowerCase(),
  };
  final index = _letters.indexOf(letter);
  if (index >= 0) return index + 1;
  return 1000 + rune;
}
