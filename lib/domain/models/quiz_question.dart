import 'word_pair.dart';

/// A prepared quiz item with randomly ordered cards.
class QuizQuestion {
  const QuizQuestion({
    required this.wordPair,
    required this.leftText,
    required this.rightText,
    required this.correctIsLeft,
  });

  final WordPair wordPair;
  final String leftText;
  final String rightText;
  final bool correctIsLeft;

  String get correctText => wordPair.correct;

  bool isCorrectChoice(bool choseLeft) => choseLeft == correctIsLeft;

  factory QuizQuestion.fromWordPair(WordPair pair, {required bool correctIsLeft}) {
    if (correctIsLeft) {
      return QuizQuestion(
        wordPair: pair,
        leftText: pair.correct,
        rightText: pair.wrong,
        correctIsLeft: true,
      );
    }

    return QuizQuestion(
      wordPair: pair,
      leftText: pair.wrong,
      rightText: pair.correct,
      correctIsLeft: false,
    );
  }
}

/// Visual feedback shown after the user selects a card.
enum AnswerOutcome { correct, wrong }

class AnswerFeedback {
  const AnswerFeedback({
    required this.outcome,
    required this.selectedLeft,
  });

  final AnswerOutcome outcome;
  final bool selectedLeft;
}
