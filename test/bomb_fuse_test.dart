import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/core/utils/bomb_fuse.dart';
import 'package:kelimatik/domain/models/study_mode.dart';

void main() {
  group('BombFuse.remainingFraction', () {
    test('starts full and ends empty', () {
      expect(BombFuse.remainingFraction(0), 1);
      expect(BombFuse.remainingFraction(1), 0);
    });

    test('ease-in keeps more fuse at the midpoint than linear', () {
      expect(BombFuse.remainingFraction(0.5), greaterThan(0.5));
    });

    test('clamps outside 0-1', () {
      expect(BombFuse.remainingFraction(-1), 1);
      expect(BombFuse.remainingFraction(2), 0);
    });
  });

  group('QuizSessionConfig.bomb', () {
    test('uses lives and has no challenge session clock', () {
      final config = QuizSessionConfig.bomb();
      expect(config.mode, StudyMode.bomb);
      expect(config.title, 'Bomba Modu');
      expect(config.consumeLives, isTrue);
      expect(config.timeLimit, isNull);
      expect(config.endOnFirstWrong, isFalse);
    });
  });
}
