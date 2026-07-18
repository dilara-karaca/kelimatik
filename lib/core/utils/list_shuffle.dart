import 'dart:math';

/// Fisher–Yates shuffle that works in-place for large lists.
void shuffleInPlace<T>(List<T> items, [Random? random]) {
  final rng = random ?? Random();
  for (var i = items.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final temp = items[i];
    items[i] = items[j];
    items[j] = temp;
  }
}

/// Returns a shuffled copy of [source] without mutating the original.
List<T> shuffledCopy<T>(List<T> source, [Random? random]) {
  final copy = List<T>.from(source);
  shuffleInPlace(copy, random);
  return copy;
}
