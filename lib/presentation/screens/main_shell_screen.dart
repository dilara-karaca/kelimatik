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
        child: _SoftTabBody(index: index),
      ),
      bottomNavigationBar: _AppBottomBar(
        index: index,
        onChanged: (i) =>
            ref.read(mainTabIndexProvider.notifier).setIndex(i),
      ),
    );
  }
}

/// Fades the active tab as one layer, then swaps — never stacks two pages.
class _SoftTabBody extends StatefulWidget {
  const _SoftTabBody({required this.index});

  final int index;

  @override
  State<_SoftTabBody> createState() => _SoftTabBodyState();
}

class _SoftTabBodyState extends State<_SoftTabBody> {
  static const _tabs = <Widget>[
    HomeScreen(embedded: true),
    WordSearchScreen(embedded: true),
    FavoritesScreen(embedded: true),
    LeaderboardScreen(embedded: true),
  ];

  late int _visibleIndex;
  double _opacity = 1;
  int _fadeToken = 0;

  @override
  void initState() {
    super.initState();
    _visibleIndex = widget.index;
  }

  @override
  void didUpdateWidget(covariant _SoftTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _animateTo(widget.index);
    }
  }

  Future<void> _animateTo(int next) async {
    final token = ++_fadeToken;
    setState(() => _opacity = 0);

    await Future<void>.delayed(AppConstants.tabTransition ~/ 2);
    if (!mounted || token != _fadeToken) return;

    setState(() {
      _visibleIndex = next;
      _opacity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: AppConstants.tabTransition ~/ 2,
      curve: AppConstants.pageCurve,
      child: IndexedStack(
        index: _visibleIndex,
        children: _tabs,
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
          duration: AppConstants.tabTransition,
          curve: AppConstants.pageCurve,
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
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: AppConstants.tabTransition,
                curve: AppConstants.pageCurve,
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: AppConstants.tabTransition,
                curve: AppConstants.pageCurve,
                style: AppTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
