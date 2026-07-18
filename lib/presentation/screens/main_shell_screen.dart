import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../providers/main_tab_provider.dart';
import '../widgets/playful_background.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'word_search_screen.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: IndexedStack(
          index: index,
          children: const [
            HomeScreen(embedded: true),
            WordSearchScreen(embedded: true),
            FavoritesScreen(embedded: true),
            LeaderboardScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: _AppBottomBar(
        index: index,
        onChanged: (i) =>
            ref.read(mainTabIndexProvider.notifier).setIndex(i),
      ),
    );
  }
}

class _AppBottomBar extends StatelessWidget {
  const _AppBottomBar({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottom),
      child: Row(
        children: [
          _NavItem(
            label: 'Ana Sayfa',
            icon: Icons.home_rounded,
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            label: 'Ara',
            icon: Icons.search_rounded,
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            label: 'Favoriler',
            icon: Icons.star_rounded,
            selected: index == 2,
            onTap: () => onChanged(2),
          ),
          _NavItem(
            label: 'Sıralama',
            icon: Icons.bar_chart_rounded,
            selected: index == 3,
            onTap: () => onChanged(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 10 : 6,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
