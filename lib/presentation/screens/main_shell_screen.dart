import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../navigation/app_navigation.dart';
import '../providers/main_tab_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_icon.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'word_search_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  void _onTabChanged(int i) {
    final nav = _shellNavigatorKey.currentState;
    if (nav != null) {
      nav.popUntil((route) => route.isFirst);
      // Drawer uses local history on the tab route; popUntil won't close it.
      if (nav.canPop()) nav.pop();
    }
    ref.read(mainTabIndexProvider.notifier).setIndex(i);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(mainTabIndexProvider);
    // Ensure settings (haptics etc.) load for quiz feedback.
    ref.watch(appSettingsProvider);

    // Nested pages / drawer first, then Ara/Favoriler/Sıralama → Ana Sayfa,
    // then leave the app. canPop is always false so we read the nested
    // navigator live (drawer local-history does not rebuild this widget).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nested = _shellNavigatorKey.currentState;
        if (nested != null && nested.canPop()) {
          nested.pop();
          return;
        }
        if (index != AppNavigation.homeTab) {
          AppNavigation.goHomeTab(ref);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: PlayfulBackground(
          child: Navigator(
            key: _shellNavigatorKey,
            onGenerateRoute: (settings) {
              return PageRouteBuilder<void>(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const _SoftTabBody();
                },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            },
          ),
        ),
        bottomNavigationBar: _AppBottomBar(
          index: index,
          onChanged: _onTabChanged,
        ),
      ),
    );
  }
}

/// Fades the active tab as one layer, then swaps — never stacks two pages.
class _SoftTabBody extends ConsumerStatefulWidget {
  const _SoftTabBody();

  @override
  ConsumerState<_SoftTabBody> createState() => _SoftTabBodyState();
}

class _SoftTabBodyState extends ConsumerState<_SoftTabBody> {
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
    _visibleIndex = ref.read(mainTabIndexProvider);
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
    ref.listen<int>(mainTabIndexProvider, (previous, next) {
      if (previous != next) _animateTo(next);
    });

    return AnimatedOpacity(
      opacity: _opacity,
      duration: AppConstants.tabTransition ~/ 2,
      curve: AppConstants.pageCurve,
      child: AnimatedSlide(
        offset: _opacity < 1 ? const Offset(0, 0.012) : Offset.zero,
        duration: AppConstants.tabTransition ~/ 2,
        curve: AppConstants.pageCurve,
        child: IndexedStack(
          index: _visibleIndex,
          children: _tabs,
        ),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottom),
        child: Row(
          children: [
            _NavItem(
              label: 'Ana Sayfa',
              icon: AppIcons.home,
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              label: 'Ara',
              icon: AppIcons.search,
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
            _NavItem(
              label: 'Favoriler',
              icon: AppIcons.favorites,
              selected: index == 2,
              onTap: () => onChanged(2),
            ),
            _NavItem(
              label: 'Sıralama',
              icon: AppIcons.league,
              selected: index == 3,
              onTap: () => onChanged(3),
            ),
          ],
        ),
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
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedPressable(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
                scale: selected ? 1.08 : 1,
                duration: AppConstants.tabTransition,
                curve: AppConstants.pageCurve,
                child: AppIcon(icon, size: 22),
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
