import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../providers/catalog_providers.dart';
import '../widgets/favorite_toggle_icon.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({super.key, required this.wordId});

  final int wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = ref.watch(wordByIdProvider(wordId));
    final fav = ref.watch(favoritesProvider).contains(wordId);

    if (word == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Kelime bulunamadı')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedPressable(
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const Spacer(),
                    AnimatedPressable(
                      child: IconButton(
                        onPressed: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(wordId),
                        icon: FavoriteToggleIcon(favorited: fav, size: 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  child: Text(
                    word.correct,
                    style: AppTypography.brand(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: AppConstants.entranceStagger,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.wrongSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Yaygın hata: ${word.wrong}',
                      style: AppTypography.title(
                        color: AppColors.wrong,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: AppConstants.entranceStagger * 2,
                  child: Text(
                    'Örnek kullanım',
                    style: AppTypography.brand(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: AppConstants.entranceStagger * 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      word.usageExample,
                      style: AppTypography.body(fontSize: 16),
                    ),
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
