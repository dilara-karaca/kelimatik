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
import '../widgets/app_error_view.dart';
import '../widgets/app_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    final favIds = ref.watch(favoritesProvider);
    final wordsAsync = ref.watch(wordsListProvider);

    final body = SafeArea(
      bottom: !widget.embedded,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(widget.embedded ? 12 : 8, 8, 8, 8),
            child: Row(
              children: [
                if (!widget.embedded)
                  IconButton(
                    onPressed: () => AppNavigation.popRoute(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: _searchOpen
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Favorilerde ara...',
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
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
                        )
                      : Text(
                          'Favoriler',
                          style: AppTypography.brand(fontSize: 24),
                        ),
                ),
                IconButton(
                  onPressed: _toggleSearch,
                  tooltip: _searchOpen ? 'Aramayı kapat' : 'Ara',
                  icon: _searchOpen
                      ? const Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                        )
                      : const AppIcon(AppIcons.search, size: 24),
                ),
                if (favIds.isNotEmpty && !_searchOpen)
                  TextButton(
                    onPressed: () => openStudySession(
                      context,
                      ref,
                      QuizSessionConfig.favorites(),
                    ),
                    child: const Text('Çalış'),
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
                final list = _filter(
                  words.where((w) => favIds.contains(w.id)).toList(),
                );
                if (favIds.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz favori yok.\nYıldız ile favorilere ekleyebilirsin.',
                      textAlign: TextAlign.center,
                      style: AppTypography.title(),
                    ),
                  );
                }
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'Aramayla eşleşen favori yok',
                      style: AppTypography.title(),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final word = list[index];
                    return SoftListAppear(
                      index: index,
                      child: AnimatedPressable(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: Text(
                              word.correct,
                              style: AppTypography.body(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              word.wrong,
                              style: AppTypography.title(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const FavoriteToggleIcon(
                                favorited: true,
                                size: 24,
                              ),
                              onPressed: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(word.id),
                            ),
                            onTap: () {
                              pushSoft(
                                context,
                                WordDetailScreen(wordId: word.id),
                              );
                            },
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
