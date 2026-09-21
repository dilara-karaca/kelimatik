import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/word_pair.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../navigation/study_navigation.dart';
import '../providers/catalog_providers.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_error_view.dart';
import '../widgets/catalog_list_ui.dart';
import '../widgets/favorite_toggle_icon.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';
import 'word_detail_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  List<WordPair> _filter(List<WordPair> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where(
          (w) =>
              w.correct.toLowerCase().contains(q) ||
              w.wrong.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _confirmRemoveFavorite(WordPair word) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Favorilerden çıkarılsın mı?',
      message: '«${word.correct}» favorilerinden kaldırılacak.',
      cancelLabel: 'İptal',
      confirmLabel: 'Evet',
    );
    if (confirmed != true || !mounted) return;
    await ref.read(favoritesProvider.notifier).toggle(word.id);
  }

  @override
  Widget build(BuildContext context) {
    final favIds = ref.watch(favoritesProvider);
    final wordsAsync = ref.watch(wordsListProvider);

    final body = SafeArea(
      bottom: !widget.embedded,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(widget.embedded ? 20 : 8, 10, 16, 8),
            child: Row(
              children: [
                if (!widget.embedded) ...[
                  CatalogCircleButton(
                    tooltip: 'Geri',
                    onTap: () => AppNavigation.popRoute(context),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _searchOpen
                      ? CatalogSearchField(
                          controller: _searchController,
                          autofocus: true,
                          hintText: 'Favorilerde ara...',
                          onChanged: (v) => setState(() => _query = v),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Favoriler',
                              style: AppTypography.brand(fontSize: 24),
                            ),
                            if (favIds.isNotEmpty)
                              Text(
                                '${favIds.length} kayıtlı kelime',
                                style: AppTypography.title(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(width: 8),
                CatalogCircleButton(
                  highlighted: _searchOpen,
                  tooltip: _searchOpen ? 'Aramayı kapat' : 'Ara',
                  onTap: _toggleSearch,
                  child: Icon(
                    _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                if (favIds.isNotEmpty && !_searchOpen) ...[
                  const SizedBox(width: 8),
                  _StudyButton(
                    onTap: () => openStudySession(
                      context,
                      ref,
                      QuizSessionConfig.favorites(),
                    ),
                  ),
                ],
              ],
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
                final list = _filter(
                  words.where((w) => favIds.contains(w.id)).toList(),
                );
                if (favIds.isEmpty) {
                  return const CatalogEmptyState(
                    icon: AppIcons.favorites,
                    title: 'Henüz favori yok',
                    message:
                        'Kelimelerin yanındaki yıldıza dokunarak\nfavorilerine ekleyebilirsin.',
                  );
                }
                if (list.isEmpty) {
                  return const CatalogEmptyState(
                    icon: AppIcons.search,
                    title: 'Eşleşme yok',
                    message: 'Aramayla eşleşen bir favori bulunamadı.',
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final word = list[index];
                    return SoftListAppear(
                      index: index,
                      child: CatalogWordTile(
                        correct: word.correct,
                        wrong: word.wrong,
                        accent: CatalogWordAccent.favorite,
                        onTap: () {
                          pushSoft(
                            context,
                            WordDetailScreen(wordId: word.id),
                          );
                        },
                        trailing: CatalogCircleButton(
                          highlighted: true,
                          tooltip: 'Favorilerden çıkar',
                          onTap: () => _confirmRemoveFavorite(word),
                          child: const FavoriteToggleIcon(
                            favorited: true,
                            size: 20,
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
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.embedded ? body : PlayfulBackground(child: body),
    );
  }
}

class _StudyButton extends StatelessWidget {
  const _StudyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 2),
            Text(
              'Çalış',
              style: AppTypography.body(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
