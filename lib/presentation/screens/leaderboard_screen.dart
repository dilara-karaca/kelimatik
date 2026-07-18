import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../providers/catalog_providers.dart';
import '../widgets/playful_background.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardProvider);

    final body = SafeArea(
      bottom: !embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(embedded ? 20 : 8, 8, 20, 8),
            child: Row(
              children: [
                if (!embedded)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Text('Sıralama', style: AppTypography.brand(fontSize: 24)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Örnek sıralama — gerçek backend sonra bağlanacak.',
              style: AppTypography.title(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (entries) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final medal = switch (e.rank) {
                      1 => AppColors.accent,
                      2 => AppColors.sky,
                      3 => AppColors.mint,
                      _ => AppColors.textSecondary,
                    };
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: medal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${e.rank}',
                            style: AppTypography.body(
                              color: medal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          e.displayName,
                          style: AppTypography.body(fontWeight: FontWeight.w700),
                        ),
                        trailing: Text(
                          '${e.score}',
                          style: AppTypography.score(
                            color: AppColors.textPrimary,
                            fontSize: 18,
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
      body: embedded ? body : PlayfulBackground(child: body),
    );
  }
}
