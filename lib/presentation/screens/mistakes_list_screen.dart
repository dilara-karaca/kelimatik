import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/mistake_entry.dart';
import '../../domain/models/word_pair.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../providers/catalog_providers.dart';
import '../widgets/app_error_view.dart';
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
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => AppNavigation.popRoute(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text(
                      'Yanlışlarım',
                      style: AppTypography.brand(fontSize: 24),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Yanlış yaptığın kelimeler. Çalışmak için ana sayfadaki Yanlışlarım modunu kullan.',
                  style: AppTypography.title(fontSize: 13),
                ),
              ),
              Expanded(
                child: wordsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorView.fromError(
                e,
                onRetry: () => ref.invalidate(wordsListProvider),
              ),
                  data: (words) {
                    final rows = _orderedRows(mistakes, words);
                    if (rows.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Text(
                            'Henüz yanlışın yok 🎉\n'
                            'Oyun oynadıkça burada tekrar etmen gereken '
                            'kelimeleri göreceksin.',
                            textAlign: TextAlign.center,
                            style: AppTypography.title(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final word = row.word;
                        final entry = row.entry;
                        return SoftListAppear(
                          index: index,
                          child: Material(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => pushSoft(
                                context,
                                WordDetailScreen(wordId: word.id),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.wrong
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: AppTypography.body(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.wrong,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            word.correct,
                                            style: AppTypography.body(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Yanlış: ${word.wrong}',
                                            style: AppTypography.title(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${entry.wrongCount}×',
                                      style: AppTypography.title(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.wrong,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
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
