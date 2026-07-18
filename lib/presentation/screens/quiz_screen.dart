import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/study_mode.dart';
import '../providers/catalog_providers.dart';
import '../providers/lives_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/lives_hearts.dart';
import '../widgets/out_of_lives_panel.dart';
import '../widgets/playful_background.dart';
import '../widgets/progress_footer.dart';
import '../widgets/score_header.dart';
import '../widgets/session_result_panel.dart';
import '../widgets/word_card.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizProvider);
    final lives = ref.watch(livesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _buildBody(context, ref, quiz, lives.current),
              ),
              if (quiz.showOutOfLivesPanel)
                OutOfLivesPanel(
                  nextLifeLabel: lives.nextLifeCountdownLabel,
                  onRestart: () {
                    ref.read(quizProvider.notifier).acknowledgeOutOfLives();
                    Navigator.of(context).pop();
                  },
                ),
              if (quiz.showResult && quiz.result != null)
                SessionResultPanel(
                  result: quiz.result!,
                  onClose: () {
                    ref.read(quizProvider.notifier).acknowledgeResult();
                    Navigator.of(context).pop();
                  },
                  onRetry: quiz.result!.mode == StudyMode.favorites
                      ? () {
                          ref.read(quizProvider.notifier).startSession(
                                QuizSessionConfig.favorites(),
                              );
                        }
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    QuizState quiz,
    int lives,
  ) {
    switch (quiz.status) {
      case QuizStatus.idle:
      case QuizStatus.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Hazırlanıyor...',
                style: AppTypography.title(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      case QuizStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                quiz.errorMessage ?? 'Bir hata oluştu.',
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        );
      case QuizStatus.ready:
        return _QuizContent(quiz: quiz, lives: lives);
    }
  }
}

class _QuizContent extends ConsumerWidget {
  const _QuizContent({
    required this.quiz,
    required this.lives,
  });

  final QuizState quiz;
  final int lives;

  WordCardVisualState _leftState() {
    final feedback = quiz.feedback;
    if (feedback == null) return WordCardVisualState.idle;
    final question = quiz.question!;
    if (feedback.outcome == AnswerOutcome.correct) {
      return feedback.selectedLeft
          ? WordCardVisualState.correct
          : WordCardVisualState.dimmed;
    }
    if (feedback.selectedLeft) return WordCardVisualState.wrong;
    return question.correctIsLeft
        ? WordCardVisualState.correct
        : WordCardVisualState.dimmed;
  }

  WordCardVisualState _rightState() {
    final feedback = quiz.feedback;
    if (feedback == null) return WordCardVisualState.idle;
    final question = quiz.question!;
    if (feedback.outcome == AnswerOutcome.correct) {
      return !feedback.selectedLeft
          ? WordCardVisualState.correct
          : WordCardVisualState.dimmed;
    }
    if (!feedback.selectedLeft) return WordCardVisualState.wrong;
    return !question.correctIsLeft
        ? WordCardVisualState.correct
        : WordCardVisualState.dimmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = quiz.question;
    if (question == null) {
      return const Center(child: Text('Soru bulunamadı.'));
    }

    final notifier = ref.read(quizProvider.notifier);
    final enabled = quiz.isInteractive;
    final showLives = quiz.config.consumeLives;
    final remaining = quiz.remainingSeconds;
    final wordId = question.wordPair.id;
    final isFavorite = ref.watch(favoritesProvider).contains(wordId);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    quiz.config.title,
                    style: AppTypography.brand(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    quiz.config.mode == StudyMode.streak
                        ? 'Seri: ${quiz.currentStreak}'
                        : 'Hangisi doğru?',
                    style: AppTypography.title(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await ref.read(favoritesProvider.notifier).toggle(wordId);
                if (!context.mounted) return;
                final nowFav = ref.read(favoritesProvider).contains(wordId);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      nowFav ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
                    ),
                    duration: const Duration(milliseconds: 1400),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (showLives) ...[
          const SizedBox(height: 4),
          LivesHearts(current: lives, size: 24, spacing: 5),
        ],
        if (remaining != null) ...[
          const SizedBox(height: 8),
          Text(
            'Kalan süre: ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
            style: AppTypography.body(
              color: AppColors.accentDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 10),
        ScoreHeader(
          correctCount: quiz.sessionCorrect,
          wrongCount: quiz.sessionWrong,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey('${question.wordPair.id}-${quiz.answeredInDeck}'),
              children: [
                Expanded(
                  child: WordCard(
                    text: question.leftText,
                    enabled: enabled,
                    visualState: _leftState(),
                    onTap: notifier.selectLeft,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: WordCard(
                    text: question.rightText,
                    enabled: enabled,
                    visualState: _rightState(),
                    onTap: notifier.selectRight,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ProgressFooter(
          current: quiz.progressCurrent,
          total: quiz.totalWords == 0 ? 1 : quiz.totalWords,
        ),
      ],
    );
  }
}
