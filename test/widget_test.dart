import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/core/constants/app_constants.dart';
import 'package:kelimatik/domain/models/lives_state.dart';
import 'package:kelimatik/domain/models/quiz_question.dart';
import 'package:kelimatik/domain/models/quiz_stats.dart';
import 'package:kelimatik/domain/models/word_pair.dart';

void main() {
  group('WordPair', () {
    test('parses json', () {
      final pair = WordPair.fromJson({
        'id': 1,
        'correct': 'herkes',
        'wrong': 'herkez',
      });

      expect(pair.id, 1);
      expect(pair.correct, 'herkes');
      expect(pair.wrong, 'herkez');
    });
  });

  group('QuizQuestion', () {
    const pair = WordPair(id: 1, correct: 'yalnız', wrong: 'yanlız');

    test('places correct on the left when requested', () {
      final question = QuizQuestion.fromWordPair(pair, correctIsLeft: true);

      expect(question.leftText, 'yalnız');
      expect(question.rightText, 'yanlız');
      expect(question.isCorrectChoice(true), isTrue);
      expect(question.isCorrectChoice(false), isFalse);
    });

    test('places correct on the right when requested', () {
      final question = QuizQuestion.fromWordPair(pair, correctIsLeft: false);

      expect(question.leftText, 'yanlız');
      expect(question.rightText, 'yalnız');
      expect(question.isCorrectChoice(false), isTrue);
    });
  });

  group('QuizStats', () {
    test('tracks success rate', () {
      var stats = QuizStats.empty.recordCorrect().recordCorrect().recordWrong();

      expect(stats.totalCorrect, 2);
      expect(stats.totalWrong, 1);
      expect(stats.successRate, closeTo(66.66, 0.1));
    });

    test('xp is 10 per correct and ignores wrong answers', () {
      final stats = QuizStats.empty
          .recordCorrect()
          .recordCorrect()
          .recordCorrect()
          .recordWrong()
          .recordWrong();

      expect(stats.totalCorrect, 3);
      expect(stats.totalWrong, 2);
      expect(stats.xp, 3 * AppConstants.xpPerCorrectAnswer);
      expect(stats.xp, 30);
    });
  });

  group('LivesState', () {
    test('loses one life and starts regen', () {
      final now = DateTime(2026, 1, 1, 12);
      final next = LivesState.full.loseOne(now);

      expect(next.current, AppConstants.maxLives - 1);
      expect(next.regenStartedAt, now);
    });

    test('regenerates lives offline', () {
      final start = DateTime(2026, 1, 1, 12);
      // Two full regen cycles should restore two lives.
      final later = start.add(AppConstants.lifeRegenDuration * 2);
      final state = LivesState(
        current: 2,
        regenStartedAt: start,
      ).refreshed(later);

      expect(state.current, 4);
      expect(state.isFull, isFalse);
    });

    test('keeps countdown after regenerating one life', () {
      final start = DateTime(2026, 1, 1, 12);
      final later = start.add(AppConstants.lifeRegenDuration);
      final state = LivesState(
        current: 0,
        regenStartedAt: start,
      ).refreshed(later);

      expect(state.current, 1);
      expect(state.isFull, isFalse);
      expect(state.regenStartedAt, isNotNull);
      expect(state.timeUntilNextLife, isNotNull);
      expect(state.nextLifeCountdownLabel, isNotEmpty);
    });

    test('starts regen when not full but anchor missing', () {
      final now = DateTime(2026, 1, 1, 12);
      final state = const LivesState(current: 2).refreshed(now);

      expect(state.current, 2);
      expect(state.regenStartedAt, now);
      final minutes = AppConstants.lifeRegenDuration.inMinutes
          .toString()
          .padLeft(2, '0');
      expect(state.nextLifeCountdownLabel, '$minutes:00');
    });
  });
}
