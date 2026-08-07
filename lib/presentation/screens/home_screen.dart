import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/study_mode.dart';
import '../navigation/soft_transitions.dart';
import '../navigation/study_navigation.dart';
import '../providers/catalog_providers.dart';
import '../providers/lives_provider.dart';
import '../providers/main_tab_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/challenge_presets_sheet.dart';
import '../widgets/playful_background.dart';
import 'word_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.embedded = false});

  final bool embedded;

  void _open(BuildContext context, Widget page) {
    pushSoft(context, page);
  }

  void _goTab(WidgetRef ref, int index) {
    ref.read(mainTabIndexProvider.notifier).setIndex(index);
  }

  Future<void> _openMode(
    BuildContext context,
    WidgetRef ref,
    StudyMode mode,
  ) async {
    switch (mode) {
      case StudyMode.classic:
        await openStudySession(context, ref, QuizSessionConfig.classic());
      case StudyMode.infinite:
        await openStudySession(context, ref, QuizSessionConfig.infinite());
      case StudyMode.mistakes:
        await openStudySession(context, ref, QuizSessionConfig.mistakes());
      case StudyMode.streak:
        await openStudySession(context, ref, QuizSessionConfig.streak());
      case StudyMode.favorites:
        await openStudySession(context, ref, QuizSessionConfig.favorites());
      case StudyMode.challenge:
        await showChallengePresetsSheet(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesProvider);
    final bestStreak = ref.watch(bestStreakProvider);
    final wordOfDay = ref.watch(wordOfTheDayProvider);
    final stats = ref.watch(statsProvider);

    final body = SafeArea(
      bottom: !embedded,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HomeHeader(
                  lives: lives.current,
                  streak: bestStreak,
                  regenLabel: lives.isFull ? null : lives.nextLifeCountdownLabel,
                ),
                const SizedBox(height: 18),
                _HeroCard(
                  wordCorrect: wordOfDay?.correct ?? '…',
                  wordHint: wordOfDay?.usageExample ?? '',
                  onSearch: () => _goTab(ref, 1),
                  onDetail: wordOfDay == null
                      ? null
                      : () => _open(
                            context,
                            WordDetailScreen(wordId: wordOfDay.id),
                          ),
                  onLeaderboard: () => _goTab(ref, 3),
                  onFavorites: () => _goTab(ref, 2),
                ),
                const SizedBox(height: 28),
                Text(
                  'Öğrenme Modları',
                  style: AppTypography.brand(fontSize: 20),
                ),
                const SizedBox(height: 14),
                _ClassicModeCard(
                  onTap: () => _openMode(context, ref, StudyMode.classic),
                ),
                const SizedBox(height: 18),
                _ModeCircleGrid(
                  onChallenge: () =>
                      _openMode(context, ref, StudyMode.challenge),
                  onMistakes: () =>
                      _openMode(context, ref, StudyMode.mistakes),
                  onStreak: () => _openMode(context, ref, StudyMode.streak),
                  onInfinite: () =>
                      _openMode(context, ref, StudyMode.infinite),
                ),
                const SizedBox(height: 28),
                _PerformanceSummary(
                  totalCorrect: stats.totalCorrect,
                  successRate: stats.successRate,
                ),
              ]),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: embedded ? body : PlayfulBackground(child: body),
    );
  }
}

/// Soft circular-friendly shadows (negative spread avoids hard square edges).
List<BoxShadow> _softShadow({Color? tint}) {
  final base = tint ?? AppColors.textPrimary;
  return [
    BoxShadow(
      color: base.withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: base.withValues(alpha: 0.05),
      blurRadius: 32,
      offset: const Offset(0, 16),
      spreadRadius: -4,
    ),
  ];
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.lives,
    required this.streak,
    this.regenLabel,
  });

  final int lives;
  final int streak;
  final String? regenLabel;

  @override
  Widget build(BuildContext context) {
    final showRegen = regenLabel != null && regenLabel!.isNotEmpty;

    return Row(
      children: [
        const Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 26),
        const SizedBox(width: 8),
        Text(
          'Kelimatik',
          style: AppTypography.brand(color: AppColors.accent, fontSize: 26),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: _softShadow(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatChip(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.wrong,
                value: '$lives',
              ),
              if (showRegen) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AppColors.accentDeep,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        regenLabel!,
                        style: AppTypography.title(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: AppColors.divider,
              ),
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.accent,
                value: '$streak',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.body(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.wordCorrect,
    required this.wordHint,
    required this.onSearch,
    required this.onDetail,
    required this.onLeaderboard,
    required this.onFavorites,
  });

  final String wordCorrect;
  final String wordHint;
  final VoidCallback onSearch;
  final VoidCallback? onDetail;
  final VoidCallback onLeaderboard;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentDeep],
        ),
        boxShadow: _softShadow(tint: AppColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba! 👋',
                      style: AppTypography.brand(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bugün öğrenmeye hazır mısın?',
                      style: AppTypography.title(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _HeroIcon(icon: Icons.search_rounded, onTap: onSearch),
              _HeroIcon(icon: Icons.star_rounded, onTap: onFavorites),
              _HeroIcon(
                icon: Icons.emoji_events_rounded,
                onTap: onLeaderboard,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onDetail,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GÜNÜN KELİMESİ',
                            style: AppTypography.title(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            wordCorrect,
                            style: AppTypography.brand(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          if (wordHint.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              wordHint,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.title(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ClassicModeCard extends StatelessWidget {
  const _ClassicModeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: _softShadow(tint: AppColors.accent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFA57A), AppColors.accent],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.bookmark_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Klasik Mod',
                              style: AppTypography.brand(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Temel yazım kuralları ile ilerle.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.title(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCircleGrid extends StatelessWidget {
  const _ModeCircleGrid({
    required this.onChallenge,
    required this.onMistakes,
    required this.onStreak,
    required this.onInfinite,
  });

  final VoidCallback onChallenge;
  final VoidCallback onMistakes;
  final VoidCallback onStreak;
  final VoidCallback onInfinite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 16.0;
        final size = (constraints.maxWidth - gap) / 2;

        Widget cell(_ModeCircleData data) => SizedBox(
              width: size,
              height: size,
              child: _ModeCircle(data: data),
            );

        return Column(
          children: [
            Row(
              children: [
                cell(
                  _ModeCircleData(
                    title: 'Challenge',
                    subtitle: 'Zamana karşı yarış',
                    color: const Color(0xFFD8F5E8),
                    iconColor: const Color(0xFF0D9F6E),
                    icon: Icons.bolt_rounded,
                    watermark: Icons.timer_outlined,
                    onTap: onChallenge,
                  ),
                ),
                SizedBox(width: gap),
                cell(
                  _ModeCircleData(
                    title: 'Yanlışlarım',
                    subtitle: 'Hatalarından öğren',
                    color: const Color(0xFFFFE3E8),
                    iconColor: const Color(0xFFE11D48),
                    icon: Icons.heart_broken_rounded,
                    watermark: Icons.priority_high_rounded,
                    onTap: onMistakes,
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            Row(
              children: [
                cell(
                  _ModeCircleData(
                    title: 'Seri Modu',
                    subtitle: 'Hatasız devam et',
                    color: const Color(0xFFFFE8D6),
                    iconColor: const Color(0xFFEA580C),
                    icon: Icons.local_fire_department_rounded,
                    watermark: Icons.auto_awesome_rounded,
                    onTap: onStreak,
                  ),
                ),
                SizedBox(width: gap),
                cell(
                  _ModeCircleData(
                    title: 'Sonsuz Mod',
                    subtitle: 'Durmadan kelime avı',
                    color: const Color(0xFFE3EEF5),
                    iconColor: const Color(0xFF475569),
                    icon: Icons.all_inclusive_rounded,
                    watermark: Icons.sync_rounded,
                    onTap: onInfinite,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ModeCircleData {
  const _ModeCircleData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.watermark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final IconData watermark;
  final VoidCallback onTap;
}

class _ModeCircle extends StatelessWidget {
  const _ModeCircle({required this.data});

  final _ModeCircleData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: _softShadow(),
      ),
      child: Material(
        color: data.color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          customBorder: const CircleBorder(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final d = constraints.maxWidth;
              // Inner safe zone for circular clip — keeps text inside the curve.
              final pad = d * 0.2;

              return Stack(
                children: [
                  Positioned(
                    right: d * 0.02,
                    bottom: d * 0.08,
                    child: Icon(
                      data.watermark,
                      size: d * 0.34,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, pad * 0.95, pad, pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          data.icon,
                          color: data.iconColor,
                          size: d * 0.145,
                        ),
                        const Spacer(),
                        Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontWeight: FontWeight.w800,
                            fontSize: (d * 0.085).clamp(13, 16),
                          ),
                        ),
                        SizedBox(height: d * 0.02),
                        Text(
                          data.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title(
                            fontSize: (d * 0.065).clamp(10, 12),
                          ).copyWith(height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PerformanceSummary extends StatelessWidget {
  const _PerformanceSummary({
    required this.totalCorrect,
    required this.successRate,
  });

  final int totalCorrect;
  final double successRate;

  String get _formattedCorrect {
    final raw = totalCorrect.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final rate = successRate.clamp(0.0, 100.0);
    final rateLabel = '%${rate.round()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performans Özeti', style: AppTypography.brand(fontSize: 20)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: _softShadow(),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.wrongSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.wrong,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOPLAM DOĞRU',
                      style: AppTypography.title(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedCorrect,
                      style: AppTypography.brand(fontSize: 26),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: _softShadow(),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'BAŞARI ORANI',
                    style: AppTypography.title(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    rateLabel,
                    style: AppTypography.title(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: rate / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
