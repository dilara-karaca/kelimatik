import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/list_shuffle.dart';
import '../../core/utils/quiz_haptics.dart';
import '../../core/utils/quiz_sounds.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/word_pair.dart';
import 'catalog_providers.dart';
import 'dependency_providers.dart';
import 'lives_provider.dart';
import 'notification_provider.dart';
import 'premium_provider.dart';
import 'stats_provider.dart';

enum QuizStatus { idle, loading, ready, empty, error }

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
    this.errorInfo,
    this.outOfLives = false,
    this.showOutOfLivesPanel = false,
    this.showResult = false,
    this.result,
    this.currentStreak = 0,
    this.remainingSeconds,
    this.bombDeadline,
    this.bombCycle = 0,
    this.bombExploding = false,
    this.bombPausedMs = 0,
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
  final AppErrorInfo? errorInfo;
  final bool outOfLives;
  final bool showOutOfLivesPanel;
  final QuizSessionConfig config;
  final DateTime startedAt;
  final bool showResult;
  final QuizSessionResult? result;
  final int currentStreak;
  final int? remainingSeconds;
  final DateTime? bombDeadline;
  final int bombCycle;
  final bool bombExploding;
  final int bombPausedMs;

  bool get isInteractive =>
      status == QuizStatus.ready &&
      feedback == null &&
      !outOfLives &&
      !showOutOfLivesPanel &&
      !showResult &&
      !bombExploding;

  /// Active run that has not reached a result or out-of-lives panel.
  bool get isInProgress =>
      status == QuizStatus.ready && !showResult && !showOutOfLivesPanel;

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
    AppErrorInfo? errorInfo,
    bool clearErrorInfo = false,
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
    DateTime? bombDeadline,
    bool clearBombDeadline = false,
    int? bombCycle,
    bool? bombExploding,
    int? bombPausedMs,
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
      errorInfo: clearErrorInfo ? null : (errorInfo ?? this.errorInfo),
      outOfLives: outOfLives ?? this.outOfLives,
      showOutOfLivesPanel: showOutOfLivesPanel ?? this.showOutOfLivesPanel,
      config: config ?? this.config,
      startedAt: startedAt ?? this.startedAt,
      showResult: showResult ?? this.showResult,
      result: clearResult ? null : (result ?? this.result),
      currentStreak: currentStreak ?? this.currentStreak,
      remainingSeconds:
          clearRemaining ? null : (remainingSeconds ?? this.remainingSeconds),
      bombDeadline:
          clearBombDeadline ? null : (bombDeadline ?? this.bombDeadline),
      bombCycle: bombCycle ?? this.bombCycle,
      bombExploding: bombExploding ?? this.bombExploding,
      bombPausedMs: bombPausedMs ?? this.bombPausedMs,
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
  Timer? _bombTimer;
  QuizSessionConfig _config = QuizSessionConfig.classic();
  var _lastTenCuePlayed = false;

  @override
  QuizState build() {
    ref.onDispose(() {
      _advanceTimer?.cancel();
      _challengeTimer?.cancel();
      _bombTimer?.cancel();
      unawaited(QuizSounds.stopAll());
    });
    return QuizState.initial;
  }

  Future<void> startSession([QuizSessionConfig? config]) async {
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    _bombTimer?.cancel();
    _lastTenCuePlayed = false;
    unawaited(QuizSounds.stopAll());
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
          status: QuizStatus.empty,
          errorMessage: _emptyMessage(),
          clearErrorInfo: true,
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
      _startBombFuse();
    } catch (error) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: null,
        errorInfo: AppErrorInfo.from(error),
      );
    }
  }

  String _emptyMessage() {
    switch (_config.mode) {
      case StudyMode.mistakes:
        return 'Henüz yanlışın yok 🎉\n'
            'Oyun oynadıkça burada tekrar etmen gereken kelimeleri göreceksin.';
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
      case StudyMode.bomb:
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
        unawaited(QuizSounds.stopTimerCue());
        _finishSession();
        return;
      }
      final next = remaining - 1;
      if (next == 10 && !_lastTenCuePlayed) {
        _lastTenCuePlayed = true;
        unawaited(QuizSounds.lastTenSeconds());
      }
      state = state.copyWith(remainingSeconds: next);
    });
  }

  void _startBombFuse({int? remainingMs}) {
    _bombTimer?.cancel();
    _bombTimer = null;
    if (_config.mode != StudyMode.bomb) return;
    if (state.showResult ||
        state.showOutOfLivesPanel ||
        state.bombExploding ||
        state.status != QuizStatus.ready) {
      return;
    }

    final total = AppConstants.bombQuestionDuration.inMilliseconds;
    final ms = remainingMs ?? total;
    if (ms <= 0) {
      _onBombTimeout();
      return;
    }

    final resetCycle = remainingMs == null;
    state = state.copyWith(
      bombDeadline: DateTime.now().add(Duration(milliseconds: ms)),
      bombCycle: resetCycle ? state.bombCycle + 1 : state.bombCycle,
      bombExploding: false,
      bombPausedMs: 0,
    );
    _bombTimer = Timer(Duration(milliseconds: ms), _onBombTimeout);
  }

  void _onBombTimeout() {
    _bombTimer = null;
    final current = state;
    if (current.showResult ||
        current.showOutOfLivesPanel ||
        current.bombExploding) {
      return;
    }
    if (current.feedback?.outcome == AnswerOutcome.correct) return;

    _advanceTimer?.cancel();
    unawaited(QuizHaptics.wrong());
    unawaited(QuizSounds.fail());
    state = current.copyWith(
      bombExploding: true,
      clearBombDeadline: true,
      bombPausedMs: 0,
    );
    _advanceTimer = Timer(
      AppConstants.bombExplosionDuration,
      completeBombExplosion,
    );
  }

  void completeBombExplosion() {
    if (!state.bombExploding || state.showResult) return;
    _finishSession();
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
    _noteStreakActivity();

    if (isCorrect) {
      unawaited(QuizHaptics.correct());
      final nextStreak = current.currentStreak + 1;
      _playCorrectSound(nextStreak: nextStreak);
      if (_config.mode == StudyMode.bomb) {
        _bombTimer?.cancel();
        _bombTimer = null;
      }
      state = current.copyWith(
        feedback: AnswerFeedback(
          outcome: AnswerOutcome.correct,
          selectedLeft: choseLeft,
        ),
        sessionCorrect: current.sessionCorrect + 1,
        answeredInDeck: current.answeredInDeck + 1,
        currentStreak: nextStreak,
        clearBombDeadline: _config.mode == StudyMode.bomb,
      );
      unawaited(ref.read(statsProvider.notifier).recordCorrect());
      if (_config.recordMistakes) {
        unawaited(ref.read(mistakesProvider.notifier).recordCorrect(wordId));
      }
      if (_config.mode == StudyMode.streak) {
        unawaited(ref.read(bestStreakProvider.notifier).consider(nextStreak));
      }
      _scheduleAdvance(AppConstants.correctFeedbackDuration);
      return;
    }

    unawaited(QuizHaptics.wrong());
    _playWrongSound(brokenStreak: current.currentStreak);
    var outOfLives = false;
    // Lives drop only on a wrong answer — never because the user left the mode.
    if (_config.consumeLives && !ref.read(premiumProvider)) {
      try {
        final lives = await ref.read(livesProvider.notifier).loseLife();
        outOfLives = lives.isEmpty;
      } catch (_) {
        outOfLives = ref.read(livesProvider).isEmpty;
      }
    }

    final afterLives = state;
    if (afterLives.bombExploding || afterLives.showResult) {
      unawaited(ref.read(statsProvider.notifier).recordWrong());
      if (_config.recordMistakes) {
        unawaited(ref.read(mistakesProvider.notifier).recordWrong(wordId));
      }
      return;
    }

    state = afterLives.copyWith(
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
      unawaited(ref.read(mistakesProvider.notifier).recordWrong(wordId));
    }

    if (state.bombExploding || state.showResult) {
      return;
    }

    if (_config.endOnFirstWrong) {
      _scheduleFinish(AppConstants.wrongFeedbackDuration);
      return;
    }

    _scheduleAdvance(AppConstants.wrongFeedbackDuration);
  }

  void _playCorrectSound({required int nextStreak}) {
    switch (_config.mode) {
      case StudyMode.streak:
        unawaited(
          QuizSounds.correct(
            streakMilestone: nextStreak > 0 && nextStreak % 5 == 0,
          ),
        );
      case StudyMode.classic:
      case StudyMode.challenge:
      case StudyMode.mistakes:
      case StudyMode.bomb:
        unawaited(QuizSounds.correct());
      case StudyMode.favorites:
        break;
    }
  }

  void _playWrongSound({required int brokenStreak}) {
    switch (_config.mode) {
      case StudyMode.streak:
        if (brokenStreak > 0) {
          unawaited(QuizSounds.fail());
        } else {
          unawaited(QuizSounds.incorrect());
        }
      case StudyMode.classic:
      case StudyMode.challenge:
      case StudyMode.mistakes:
      case StudyMode.bomb:
        unawaited(QuizSounds.incorrect());
      case StudyMode.favorites:
        break;
    }
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
    if (current.bombExploding) return;
    if (current.outOfLives) {
      _bombTimer?.cancel();
      _bombTimer = null;
      state = current.copyWith(
        showOutOfLivesPanel: true,
        clearBombDeadline: true,
      );
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

    final resetBomb = _config.mode == StudyMode.bomb &&
        (current.feedback?.outcome == AnswerOutcome.correct ||
            _bombTimer == null);

    state = current.copyWith(
      order: order,
      cursor: nextCursor,
      question: _buildQuestion(current.words, order[nextCursor]),
      clearFeedback: true,
      outOfLives: false,
      showOutOfLivesPanel: false,
    );

    if (resetBomb) {
      _startBombFuse();
    }
  }

  void _finishSession() {
    _challengeTimer?.cancel();
    _advanceTimer?.cancel();
    _bombTimer?.cancel();
    _bombTimer = null;
    unawaited(QuizSounds.stopTimerCue());
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
      clearBombDeadline: true,
    );
  }

  void acknowledgeOutOfLives() {
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    _bombTimer?.cancel();
    _bombTimer = null;
    unawaited(QuizSounds.stopAll());
    state = state.copyWith(
      outOfLives: false,
      showOutOfLivesPanel: false,
      clearFeedback: true,
      status: QuizStatus.idle,
      clearBombDeadline: true,
      bombExploding: false,
    );
  }

  /// After a rewarded +1 life: dismiss out-of-lives UI and continue the deck.
  void resumeAfterLifeGained() {
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    _bombTimer?.cancel();
    _bombTimer = null;
    if (!state.showOutOfLivesPanel && !state.outOfLives) return;
    state = state.copyWith(
      outOfLives: false,
      showOutOfLivesPanel: false,
      clearFeedback: true,
      clearBombDeadline: true,
    );
    _advance();
  }

  void acknowledgeResult() {
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    _bombTimer?.cancel();
    _bombTimer = null;
    unawaited(QuizSounds.stopAll());
    state = QuizState.initial;
  }

  /// Stops the challenge countdown while an exit prompt is visible.
  /// Does not change lives or session scores.
  void pauseSessionClock() {
    _challengeTimer?.cancel();
    _challengeTimer = null;
    unawaited(QuizSounds.stopTimerCue());

    _bombTimer?.cancel();
    _bombTimer = null;
    final deadline = state.bombDeadline;
    if (deadline != null) {
      final remaining = deadline.difference(DateTime.now()).inMilliseconds;
      if (remaining <= 0) {
        _onBombTimeout();
        return;
      }
      state = state.copyWith(
        clearBombDeadline: true,
        bombPausedMs: remaining.clamp(
          1,
          AppConstants.bombQuestionDuration.inMilliseconds,
        ),
      );
    }
  }

  /// Restarts the challenge countdown after the user chooses to stay.
  void resumeSessionClock() {
    if (state.showResult || state.showOutOfLivesPanel || state.outOfLives) {
      return;
    }
    if (state.status != QuizStatus.ready) return;
    if (state.bombExploding) return;
    _startChallengeClock();
    if (_config.mode == StudyMode.bomb && state.bombPausedMs > 0) {
      _startBombFuse(remainingMs: state.bombPausedMs);
    }
  }

  /// Leaves the current run without finishing it and without losing a life.
  /// Per-answer stats/mistakes already recorded stay; in-mode score/cursor do not.
  void abandonSession() {
    if (state.showResult) {
      acknowledgeResult();
      return;
    }
    _advanceTimer?.cancel();
    _challengeTimer?.cancel();
    _bombTimer?.cancel();
    _advanceTimer = null;
    _challengeTimer = null;
    _bombTimer = null;
    unawaited(QuizSounds.stopAll());
    state = QuizState.initial;
  }

  /// Records local clock time of a streak-advancing play without changing
  /// streak math. Used only to schedule the next day's reminder.
  void _noteStreakActivity() {
    unawaited(
      ref
          .read(notificationCoordinatorProvider)
          .recordStreakActivity(DateTime.now()),
    );
  }
}
