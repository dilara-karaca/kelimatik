import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/mistake_entry.dart';
import '../../domain/models/word_pair.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../providers/catalog_providers.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_icon.dart';
import '../widgets/catalog_list_ui.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';
import 'word_detail_screen.dart';

/// Read-only list of missed words (not a playable study mode).
class MistakesListScreen extends ConsumerWidget {
  const MistakesListScreen({super.key});

  List<({MistakeEntry entry, WordPair word})> _orderedRows(
    List<MistakeEntry> mistakes,
    List<WordPair> words,
  ) {
    final byId = {for (final w in words) w.id: w};
    final rows = <({MistakeEntry entry, WordPair word})>[];
    for (final entry in mistakes) {
      final word = byId[entry.wordId];
      if (word == null) continue;
      rows.add((entry: entry, word: word));
    }
    rows.sort((a, b) {
      final byWrong = b.entry.wrongCount.compareTo(a.entry.wrongCount);
      if (byWrong != 0) return byWrong;
      return b.entry.lastMissedAt.compareTo(a.entry.lastMissedAt);
    });
    return rows;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = ref.watch(mistakesProvider);
    final wordsAsync = ref.watch(wordsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 20, 8),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Geri',
                      child: AnimatedPressable(
                        onTap: () => AppNavigation.popRoute(context),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(6, 6, 2, 6),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 26,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Yanlışlarım',
                        style: AppTypography.brand(fontSize: 24),
                      ),
                    ),
                    wordsAsync.maybeWhen(
                      data: (words) {
                        final n = _orderedRows(mistakes, words).length;
                        if (n == 0) return const SizedBox.shrink();
                        return CatalogCountChip(
                          label: '$n kelime',
                          color: AppColors.wrong,
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: AppColors.modeMistakes,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const AppIcon(AppIcons.mistakesMode, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yanlış yaptığın kelimeler burada listelenir. Çalışmak için ana sayfadaki Yanlışlarım modunu kullan.',
                          style: AppTypography.title(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: wordsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (e, _) => AppErrorView.fromError(
                    e,
                    onRetry: () => ref.invalidate(wordsListProvider),
                  ),
                  data: (words) {
                    final rows = _orderedRows(mistakes, words);
                    if (rows.isEmpty) {
                      return const CatalogEmptyState(
                        icon: AppIcons.mistakesMode,
                        iconTint: AppColors.wrong,
                        title: 'Henüz yanlışın yok',
                        message:
                            'Oyun oynadıkça burada tekrar etmen gereken kelimeleri göreceksin.',
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final word = row.word;
                        final entry = row.entry;
                        return SoftListAppear(
                          index: index,
                          child: CatalogWordTile(
                            correct: word.correct,
                            wrong: word.wrong,
                            accent: CatalogWordAccent.mistake,
                            onTap: () => pushSoft(
                              context,
                              WordDetailScreen(wordId: word.id),
                            ),
                            leading: _RankBadge(index: index + 1),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.wrongSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${entry.wrongCount}×',
                                    style: AppTypography.title(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.wrong,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.wrong.withValues(alpha: 0.18),
            AppColors.wrong.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$index',
        style: AppTypography.body(
          fontWeight: FontWeight.w800,
          color: AppColors.wrong,
          fontSize: 14,
        ),
      ),
    );
  }
}
