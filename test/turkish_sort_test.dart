import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/core/utils/turkish_sort.dart';

void main() {
  test('orders the Turkish alphabet from a to z', () {
    final words = [
      'şoför',
      'çare',
      'ığne',
      'inek',
      'güzel',
      'gazete',
      'öğretmen',
      'okul',
      'üzüm',
      'uzun',
      'zeytin',
      'araba',
    ];

    words.sort(compareTurkish);

    expect(words, [
      'araba',
      'çare',
      'gazete',
      'güzel',
      'ığne',
      'inek',
      'okul',
      'öğretmen',
      'şoför',
      'uzun',
      'üzüm',
      'zeytin',
    ]);
  });

  test('puts a shorter prefix and a spaced phrase first', () {
    final words = ['biraz', 'bir an', 'bir şey', 'bir'];
    words.sort(compareTurkish);
    expect(words, ['bir', 'bir an', 'bir şey', 'biraz']);
  });
}
