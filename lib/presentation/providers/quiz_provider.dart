import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/list_shuffle.dart';
import '../../core/utils/quiz_haptics.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/word_pair.dart';
import 'catalog_providers.dart';
import 'dependency_providers.dart';
import 'lives_provider.dart';
import 'stats_provider.dart';

enum QuizStatus { idle, loading, ready, error }

class QuizState {
  const QuizState({
    required this.status,
    required this.words,
    required this.order,
    required this.cursor,
    required this.question,
    required this.sessionCorrect,
    required this.sessionWrong,
    required this.answeredInDeck,
    required this.config,
    required this.startedAt,
    this.feedback,
    this.errorMessage,
    this.outOfLives = false,
    this.showOutOfLivesPanel = false,
    this.showResult = false,
    this.result,
    this.currentStreak = 0,
    this.remainingSeconds,
  });

  final QuizStatus status;
  final List<WordPair> words;
  final List<int> order;
  final int cursor;
  final QuizQuestion? question;
  final AnswerFeedback? feedback;
  final int sessionCorrect;
  final int sessionWrong;
  final int answeredInDeck;
  final String? errorMessage;
  final bool outOfLives;
  final bool showOutOfLivesPanel;
  final QuizSessionConfig config;
  final DateTime startedAt;
  final bool showResult;
  final QuizSessionResult? result;
  final int currentStreak;
  final int? remainingSeconds;

  bool get isInteractive =>
      status == QuizStatus.ready &&
      feedback == null &&
      !outOfLives &&
      !showOutOfLivesPanel &&
      !showResult;

  int get totalWords {
    final target = config.targetCount;
    if (target != null) return target;
    return words.length;
  }

  int get progressCurrent {
    if (config.targetCount != null) {
      return answeredInDeck.clamp(0, config.targetCount!);
    }
    if (words.isEmpty) return 0;
    return cursor + 1;
  }

  QuizState copyWith({
    QuizStatus? status,
    List<WordPair>? words,
    List<int>? order,
    int? cursor,
    QuizQuestion? question,
    AnswerFeedback? feedback,
    bool clearFeedback = false,
    int? sessionCorrect,
    int? sessionWrong,
    int? answeredInDeck,
    String? errorMessage,
    bool? outOfLives,
    bool? showOutOfLivesPanel,
    QuizSessionConfig? config,
    DateTime? startedAt,
    bool? showResult,
    QuizSessionResult? result,
    bool clearResult = false,
    int? currentStreak,
    int? remainingSeconds,
    bool clearRemaining = false,
  }) {
    return QuizState(
      status: status ?? this.status,
      words: words ?? this.words,
      order: order ?? this.order,
      cursor: cursor ?? this.cursor,
      question: question ?? this.question,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      sessionCorrect: sessionCorrect ?? this.sessionCorrect,
      sessionWrong: sessionWrong ?? this.sessionWrong,
      answeredInDeck: answeredInDeck ?? this.answeredInDeck,
      errorMessage: errorMessage ?? this.errorMessage,
      outOfLives: outOfLives ?? this.outOfLives,
      showOutOfLivesPanel: showOutOfLivesPanel ?? this.showOutOfLivesPanel,
      config: config ?? this.config,
      startedAt: startedAt ?? this.startedAt,
      showResult: showResult ?? this.showResult,
      result: clearResult ? null : (result ?? this.result),
      currentStreak: currentStreak ?? this.currentStreak,
      remainingSeconds:
          clearRemaining ? null : (remainingSeconds ?? this.remainingSeconds),
    );
  }

  static QuizState get initial => QuizState(
        status: QuizStatus.idle,
        words: const [],
        order: const [],
        cursor: 0,
        question: null,
        sessionCorrect: 0,
        sessionWrong: 0,
        answeredInDeck: 0,
        config: QuizSessionConfig.classic(),
        startedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);

class QuizNotifier extends Notifier<QuizState> {
  final Random _random = Random();
  Timer? _advanceTimer;
  Timer? _challengeTimer;
  QuizSessionConfig _config = QuizSessionConfig.classic();

  @override
  QuizState build() {
    ref.onDispose(() {
      _advanceTimer?.cancel();
      _challengeTimer?.cancel();
    });
    return QuizState.initial;
  }

  Future<void> startSession([QuizSessionConfig? config]) async {
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    _config = config ?? QuizSessionConfig.classic();
    state = QuizState.initial.copyWith(
      status: QuizStatus.loading,
      config: _config,
    );
    await _load();
  }

  /// Backwards-compatible entry used by older call sites.
  Future<void> load() => startSession(_config);

  Future<void> _load() async {
    try {
      final allWords = await ref.read(wordRepositoryProvider).getAllWords();
      final words = _resolveWordPool(allWords);
      if (words.isEmpty) {
        state = state.copyWith(
          status: QuizStatus.error,
          errorMessage: _emptyMessage(),
        );
        return;
      }

      final order = List<int>.generate(words.length, (i) => i);
      shuffleInPlace(order, _random);
      final now = DateTime.now();

      state = QuizState(
        status: QuizStatus.ready,
        words: words,
        order: order,
        cursor: 0,
        question: _buildQuestion(words, order[0]),
        sessionCorrect: 0,
        sessionWrong: 0,
        answeredInDeck: 0,
        config: _config,
        startedAt: now,
        remainingSeconds: _config.timeLimit?.inSeconds,
        currentStreak: 0,
      );

      _startChallengeClock();
    } catch (error) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: 'Kelimeler yüklenemedi: $error',
      );
    }
  }

  String _emptyMessage() {
    switch (_config.mode) {
      case StudyMode.mistakes:
        return 'Henüz yanlış kelimen yok. Klasik modda çalışmaya başla!';
      case StudyMode.favorites:
        return 'Favori kelimen yok. Arama veya detaydan favori ekleyebilirsin.';
      default:
        return 'Kelime listesi boş.';
    }
  }

  List<WordPair> _resolveWordPool(List<WordPair> all) {
    switch (_config.mode) {
      case StudyMode.mistakes:
        // Refresh from disk; drop orphan IDs left after words.json renumbers.
        ref.read(mistakesProvider.notifier).reload();
        final knownIds = all.map((w) => w.id).toSet();
        final ids = ref
            .read(mistakesProvider)
            .map((e) => e.wordId)
            .where(knownIds.contains)
            .toSet();
        return all.where((w) => ids.contains(w.id)).toList();
      case StudyMode.favorites:
        final ids = ref.read(favoritesRepositoryProvider).loadIds();
        return all.where((w) => ids.contains(w.id)).toList();
      case StudyMode.classic:
      case StudyMode.challenge:
      case StudyMode.streak:
      case StudyMode.infinite:
        return all;
    }
  }

  void _startChallengeClock() {
    _challengeTimer?.cancel();
    if (_config.timeLimit == null) return;
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingSeconds;
      if (remaining == null) return;
      if (remaining <= 1) {
        _challengeTimer?.cancel();
        _finishSession();
        return;
      }
      state = state.copyWith(remainingSeconds: remaining - 1);
    });
  }

  QuizQuestion _buildQuestion(List<WordPair> words, int wordIndex) {
    return QuizQuestion.fromWordPair(
      words[wordIndex],
      correctIsLeft: _random.nextBool(),
    );
  }

  void selectLeft() => unawaited(_select(choseLeft: true));

  void selectRight() => unawaited(_select(choseLeft: false));

  Future<void> _select({required bool choseLeft}) async {
    final current = state;
    if (!current.isInteractive || current.question == null) return;

    final question = current.question!;
    final isCorrect = question.isCorrectChoice(choseLeft);
    final wordId = question.wordPair.id;

    if (isCorrect) {
      unawaited(QuizHaptics.correct());
      final nextStreak = current.currentStreak + 1;
      state = current.copyWith(
        feedback: AnswerFeedback(
          outcome: AnswerOutcome.correct,
          selectedLeft: choseLeft,
        ),
        sessionCorrect: current.sessionCorrect + 1,
        answeredInDeck: current.answeredInDeck + 1,
        currentStreak: nextStreak,
      );
      unawaited(ref.read(statsProvider.notifier).recordCorrect());
      if (_config.recordMistakes) {
        await ref.read(mistakesProvider.notifier).recordCorrect(wordId);
      }
      if (_config.mode == StudyMode.streak) {
        unawaited(ref.read(bestStreakProvider.notifier).consider(nextStreak));
      }
      _scheduleAdvance(AppConstants.correctFeedbackDuration);
      return;
    }

    unawaited(QuizHaptics.wrong());
    var outOfLives = false;
    if (_config.consumeLives) {
      final lives = await ref.read(livesProvider.notifier).loseLife();
      outOfLives = lives.isEmpty;
    }

    state = current.copyWith(
      feedback: AnswerFeedback(
        outcome: AnswerOutcome.wrong,
        selectedLeft: choseLeft,
      ),
      sessionWrong: current.sessionWrong + 1,
      answeredInDeck: current.answeredInDeck + 1,
      outOfLives: outOfLives,
      currentStreak: 0,
    );
    unawaited(ref.read(statsProvider.notifier).recordWrong());
    if (_config.recordMistakes) {
      // Await so Yanlışlarım sees the entry even if the user leaves quickly.
      await ref.read(mistakesProvider.notifier).recordWrong(wordId);
    }

    if (_config.endOnFirstWrong) {
      _scheduleFinish(AppConstants.wrongFeedbackDuration);
      return;
    }

    _scheduleAdvance(AppConstants.wrongFeedbackDuration);
  }

  void _scheduleAdvance(Duration delay) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, _advance);
  }

  void _scheduleFinish(Duration delay) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, _finishSession);
  }

  void _advance() {
    final current = state;
    if (current.outOfLives) {
      state = current.copyWith(showOutOfLivesPanel: true);
      return;
    }
    if (current.showResult) return;
    if (current.words.isEmpty || current.order.isEmpty) return;

    final target = current.config.targetCount;
    if (target != null && current.answeredInDeck >= target) {
      _finishSession();
      return;
    }

    var nextCursor = current.cursor + 1;
    var order = current.order;

    if (nextCursor >= order.length) {
      if (_config.endWhenDeckComplete) {
        _finishSession();
        return;
      }
      order = List<int>.from(order);
      shuffleInPlace(order, _random);
      nextCursor = 0;
    }

    state = current.copyWith(
      order: order,
      cursor: nextCursor,
      question: _buildQuestion(current.words, order[nextCursor]),
      clearFeedback: true,
      outOfLives: false,
      showOutOfLivesPanel: false,
    );
  }

  void _finishSession() {
    _challengeTimer?.cancel();
    _advanceTimer?.cancel();
    final current = state;
    final best = ref.read(bestStreakProvider);
    final result = QuizSessionResult(
      mode: current.config.mode,
      correct: current.sessionCorrect,
      wrong: current.sessionWrong,
      answered: current.answeredInDeck,
      elapsed: DateTime.now().difference(current.startedAt),
      currentStreak: current.config.mode == StudyMode.streak
          ? current.sessionCorrect
          : current.currentStreak,
      bestStreak: best,
    );
    state = current.copyWith(
      showResult: true,
      result: result,
      clearFeedback: true,
    );
  }

  void acknowledgeOutOfLives() {
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    state = state.copyWith(
      outOfLives: false,
      showOutOfLivesPanel: false,
      clearFeedback: true,
      status: QuizStatus.idle,
    );
  }

  void acknowledgeResult() {
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    state = QuizState.initial;
  }
}
