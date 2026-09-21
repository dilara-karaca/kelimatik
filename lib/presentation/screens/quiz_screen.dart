import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/ads/rewarded_ad_service.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/study_mode.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../providers/ads_provider.dart';
import '../providers/catalog_providers.dart';
import '../providers/lives_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/ads/ad_banner.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_icon.dart';
import '../widgets/bomb_fuse_bar.dart';
import '../widgets/favorite_toggle_icon.dart';
import '../widgets/lives_hearts.dart';
import '../widgets/motion/motion.dart';
import '../widgets/out_of_lives_panel.dart';
import '../widgets/playful_background.dart';
import '../widgets/progress_footer.dart';
import '../widgets/score_header.dart';
import '../widgets/session_result_panel.dart';
import '../widgets/word_card.dart';
import 'premium_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  var _exitPromptOpen = false;

  void _leaveToOrigin() {
    AppNavigation.popRoute(context);
  }

  void _leaveToHome() {
    AppNavigation.leaveToHome(context, ref);
  }

  Future<void> _requestExit({required bool toHome}) async {
    if (_exitPromptOpen) return;
    final quiz = ref.read(quizProvider);
    final notifier = ref.read(quizProvider.notifier);

    if (quiz.showOutOfLivesPanel) {
      notifier.acknowledgeOutOfLives();
      _leaveToHome();
      return;
    }

    if (quiz.showResult) {
      notifier.acknowledgeResult();
      _leaveToOrigin();
      return;
    }

    if (quiz.bombExploding) return;

    if (quiz.status != QuizStatus.ready) {
      notifier.abandonSession();
      _leaveToOrigin();
      return;
    }

    _exitPromptOpen = true;
    notifier.pauseSessionClock();
    final leave = await showAppConfirmDialog(
      context,
      title: 'Çıkmak istediğine emin misin?',
      message: 'Bu moddaki ilerlemen kaybolacak.',
      cancelLabel: 'Devam Et',
      confirmLabel: 'Çık',
      destructive: true,
    );
    if (!mounted) return;
    _exitPromptOpen = false;

    final latest = ref.read(quizProvider);
    if (leave == true) {
      if (latest.showResult) {
        ref.read(quizProvider.notifier).acknowledgeResult();
      } else {
        ref.read(quizProvider.notifier).abandonSession();
      }
      if (toHome) {
        _leaveToHome();
      } else {
        _leaveToOrigin();
      }
      return;
    }

    ref.read(quizProvider.notifier).resumeSessionClock();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final lives = ref.watch(livesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_requestExit(toHome: false));
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PlayfulBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: _buildBody(quiz, lives.current),
                      ),
                      if (quiz.showOutOfLivesPanel)
                        const Positioned.fill(
                          child: _OutOfLivesAdOverlay(),
                        ),
                      if (quiz.showResult && quiz.result != null)
                        Positioned.fill(
                          child: SessionResultPanel(
                            result: quiz.result!,
                            onClose: () {
                              ref
                                  .read(quizProvider.notifier)
                                  .acknowledgeResult();
                              if (quiz.result!.mode == StudyMode.streak) {
                                _leaveToHome();
                              } else {
                                _leaveToOrigin();
                              }
                            },
                            onRetry: switch (quiz.result!.mode) {
                              StudyMode.favorites => () {
                                  ref
                                      .read(quizProvider.notifier)
                                      .startSession(
                                        QuizSessionConfig.favorites(),
                                      );
                                },
                              StudyMode.streak => () {
                                  ref
                                      .read(quizProvider.notifier)
                                      .startSession(
                                        QuizSessionConfig.streak(),
                                      );
                                },
                              StudyMode.bomb => () {
                                  ref
                                      .read(quizProvider.notifier)
                                      .startSession(
                                        QuizSessionConfig.bomb(),
                                      );
                                },
                              _ => null,
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                // Single quiz banner: below content, above system inset (SafeArea).
                const Center(child: AdBanner()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(QuizState quiz, int lives) {
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
      case QuizStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quiz.errorMessage ?? 'Liste boş.',
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => unawaited(_requestExit(toHome: false)),
                  child: Text(
                    'Geri Dön',
                    style: AppTypography.body(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      case QuizStatus.error:
        return AppErrorView(
          info: quiz.errorInfo ?? AppErrorInfo.loadFailed,
          onRetry: () => ref.read(quizProvider.notifier).load(),
          secondaryLabel: 'Geri Dön',
          onSecondary: () => unawaited(_requestExit(toHome: false)),
        );
      case QuizStatus.ready:
        return _QuizContent(
          quiz: quiz,
          lives: lives,
          onExit: () => unawaited(_requestExit(toHome: false)),
        );
    }
  }
}

class _QuizContent extends ConsumerWidget {
  const _QuizContent({
    required this.quiz,
    required this.lives,
    required this.onExit,
  });

  final QuizState quiz;
  final int lives;
  final VoidCallback onExit;

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
              onPressed: onExit,
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
                  if (quiz.config.mode == StudyMode.streak)
                    _StreakCountBadge(count: quiz.currentStreak)
                  else
                    Text(
                      'Hangisi doğru?',
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
                try {
                  await ref.read(favoritesProvider.notifier).toggle(wordId);
                  if (!context.mounted) return;
                  final nowFav = ref.read(favoritesProvider).contains(wordId);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nowFav
                            ? 'Favorilere eklendi'
                            : 'Favorilerden çıkarıldı',
                      ),
                      duration: const Duration(milliseconds: 1400),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
              icon: FavoriteToggleIcon(favorited: isFavorite, size: 24),
            ),
          ],
        ),
        if (showLives) ...[
          const SizedBox(height: 4),
          LivesHearts(current: lives, size: 24, spacing: 5),
        ],
        if (quiz.config.mode == StudyMode.bomb) ...[
          const SizedBox(height: 8),
          BombFuseBar(
            cycle: quiz.bombCycle,
            deadline: quiz.bombDeadline,
            pausedMs: quiz.bombPausedMs,
            exploding: quiz.bombExploding,
            frozen: quiz.feedback?.outcome == AnswerOutcome.correct,
            onExplosionFinished: () {
              ref.read(quizProvider.notifier).completeBombExplosion();
            },
          ),
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
            duration: AppConstants.cardSwap,
            switchInCurve: AppConstants.pageCurve,
            switchOutCurve: AppConstants.pageReverseCurve,
            transitionBuilder: softFadeSlideTransition,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
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

class _StreakCountBadge extends StatelessWidget {
  const _StreakCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon(AppIcons.streakActive, size: 22),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: AppConstants.cardSwap,
          switchInCurve: AppConstants.pageCurve,
          switchOutCurve: AppConstants.pageReverseCurve,
          transitionBuilder: softFadeSlideTransition,
          child: Text(
            '$count',
            key: ValueKey(count),
            style: AppTypography.score(
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// Out-of-lives UI + rewarded ad → +1 can (only after a full watch).
class _OutOfLivesAdOverlay extends ConsumerStatefulWidget {
  const _OutOfLivesAdOverlay();

  @override
  ConsumerState<_OutOfLivesAdOverlay> createState() =>
      _OutOfLivesAdOverlayState();
}

class _OutOfLivesAdOverlayState extends ConsumerState<_OutOfLivesAdOverlay> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Ensure a rewarded unit is warming while the panel is visible.
    Future.microtask(() {
      ref.read(adServiceProvider).preloadFullScreenAds();
    });
  }

  Future<void> _watchAdForLife() async {
    if (_busy) return;
    setState(() => _busy = true);

    final ads = ref.read(adServiceProvider);
    final result = await ads.showRewarded(
      onUserEarnedReward: () async {
        await ref.read(livesProvider.notifier).gainLife();
      },
    );

    if (!mounted) return;

    // Resume only when AdMob confirmed a full watch AND life was applied.
    if (result == RewardedAdShowResult.rewarded &&
        ref.read(livesProvider).canPlay) {
      ref.read(quizProvider.notifier).resumeAfterLifeGained();
    } else if (result == RewardedAdShowResult.unavailable) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam şu an yüklenemedi. Biraz sonra tekrar dene.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(premiumProvider, (previous, next) {
      if (next) {
        ref.read(quizProvider.notifier).resumeAfterLifeGained();
      }
    });

    final lives = ref.watch(livesProvider);

    return OutOfLivesPanel(
      nextLifeLabel: lives.nextLifeCountdownLabel,
      watchAdEnabled: !_busy,
      onWatchAd: _watchAdForLife,
      onOpenPremium: () {
        pushSoftFullscreen(context, const PremiumScreen());
      },
      onRestart: () {
        ref.read(quizProvider.notifier).acknowledgeOutOfLives();
        AppNavigation.leaveToHome(context, ref);
      },
    );
  }
}
