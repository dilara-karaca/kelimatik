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
import '../widgets/app_icon.dart';
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
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(widget.embedded ? 20 : 12, 8, 16, 8),
            child: Row(
              children: [
                if (!widget.embedded)
                  IconButton(
                    onPressed: () => AppNavigation.popRoute(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: !widget.embedded,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Doğru veya yanlış yazımı ara...',
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: AppIcon(AppIcons.search, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: wordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                  return Center(
                    child: Text('Sonuç yok', style: AppTypography.title()),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return SoftListAppear(
                      index: index,
                      child: AnimatedPressable(
                        child: _WordTile(word: filtered[index]),
                      ),
                    );
                  },
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          word.correct,
          style: AppTypography.body(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Yanlış: ${word.wrong}',
          style: AppTypography.title(fontSize: 12),
        ),
        trailing: IconButton(
          onPressed: () =>
              ref.read(favoritesProvider.notifier).toggle(word.id),
          tooltip: fav ? 'Favorilerden çıkar' : 'Favorilere ekle',
          icon: FavoriteToggleIcon(favorited: fav, size: 24),
        ),
        onTap: () {
          pushSoft(context, WordDetailScreen(wordId: word.id));
        },
      ),
    );
  }
}
