import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/word_pair.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../providers/catalog_providers.dart';
import '../widgets/app_error_view.dart';
import '../widgets/catalog_list_ui.dart';
import '../widgets/favorite_toggle_icon.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';
import 'word_detail_screen.dart';

class WordSearchScreen extends ConsumerStatefulWidget {
  const WordSearchScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends ConsumerState<WordSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsListProvider);
    final body = SafeArea(
      bottom: !widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(widget.embedded ? 20 : 8, 10, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.embedded)
                  CatalogCircleButton(
                    tooltip: 'Geri',
                    onTap: () => AppNavigation.popRoute(context),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (!widget.embedded) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ara',
                        style: AppTypography.brand(fontSize: 26),
                      ),
                      Text(
                        'Doğru yazımı hemen bul',
                        style: AppTypography.title(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                wordsAsync.maybeWhen(
                  data: (words) => CatalogCountChip(
                    label: '${words.length} kelime',
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: CatalogSearchField(
              controller: _controller,
              autofocus: !widget.embedded,
              hintText: 'Doğru veya yanlış yazımı ara...',
              onChanged: (v) => setState(() => _query = v.trim()),
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
                final q = _query.toLowerCase();
                final filtered = q.isEmpty
                    ? List<WordPair>.from(words)
                    : words
                        .where((w) {
                          final correct = w.correct.toLowerCase();
                          final wrong = w.wrong.toLowerCase();
                          return correct.contains(q) || wrong.contains(q);
                        })
                        .toList();
                if (filtered.isEmpty) {
                  return CatalogEmptyState(
                    icon: AppIcons.search,
                    title: 'Sonuç yok',
                    message: q.isEmpty
                        ? 'Henüz listelenecek kelime yok.'
                        : '“$_query” ile eşleşen bir yazım bulunamadı.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (q.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 2, 24, 6),
                        child: Text(
                          '${filtered.length} sonuç',
                          style: AppTypography.title(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return SoftListAppear(
                            index: index,
                            child: _WordTile(word: filtered[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.embedded ? body : PlayfulBackground(child: body),
    );
  }
}

class _WordTile extends ConsumerWidget {
  const _WordTile({required this.word});

  final WordPair word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider).contains(word.id);
    return CatalogWordTile(
      correct: word.correct,
      wrong: word.wrong,
      accent: CatalogWordAccent.search,
      onTap: () => pushSoft(context, WordDetailScreen(wordId: word.id)),
      trailing: CatalogCircleButton(
        highlighted: fav,
        tooltip: fav ? 'Favorilerden çıkar' : 'Favorilere ekle',
        onTap: () => ref.read(favoritesProvider.notifier).toggle(word.id),
        child: FavoriteToggleIcon(favorited: fav, size: 20),
      ),
    );
  }
}
