import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../features/profile/profile_provider.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../providers/auth_provider.dart';
import '../providers/main_tab_provider.dart';
import '../screens/mistakes_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import 'app_dialogs.dart';
import 'app_icon.dart';
import 'kelimatik_wordmark.dart';

/// Left-side navigation menu opened from the home header hamburger.
class AppSideDrawer extends ConsumerWidget {
  const AppSideDrawer({super.key});

  void _goTab(BuildContext context, WidgetRef ref, int index) {
    Navigator.of(context).pop(); // close drawer
    ref.read(mainTabIndexProvider.notifier).setIndex(index);
  }

  Future<void> _openPage(BuildContext context, WidgetRef ref, Widget page) async {
    Navigator.of(context).pop(); // close drawer
    // Drawer is only opened from Ana Sayfa — keep that tab underneath.
    ref.read(mainTabIndexProvider.notifier).setIndex(AppNavigation.homeTab);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!context.mounted) return;
    await pushSoft(context, page);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Show dialog first — popping the drawer invalidates this context.
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Çıkış Yap',
      message: 'Hesabından çıkmak istediğine emin misin?',
      confirmLabel: 'Çıkış Yap',
      destructive: true,
    );
    if (confirmed != true) return;
    if (context.mounted) {
      Navigator.of(context).pop(); // close drawer
    }
    await ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).profile;
    final tab = ref.watch(mainTabIndexProvider);

    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Expanded(child: KelimatikWordmark(fontSize: 22)),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                profile == null
                    ? 'Menü'
                    : 'Merhaba, ${profile.username}',
                style: AppTypography.title(fontSize: 13),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerTile(
                    icon: AppIcons.home,
                    label: 'Ana Sayfa',
                    selected: tab == 0,
                    onTap: () => _goTab(context, ref, 0),
                  ),
                  _DrawerTile(
                    icon: AppIcons.search,
                    label: 'Ara',
                    selected: tab == 1,
                    onTap: () => _goTab(context, ref, 1),
                  ),
                  _DrawerTile(
                    icon: AppIcons.favorites,
                    label: 'Favoriler',
                    selected: tab == 2,
                    onTap: () => _goTab(context, ref, 2),
                  ),
                  _DrawerTile(
                    icon: AppIcons.league,
                    label: 'Sıralama',
                    selected: tab == 3,
                    onTap: () => _goTab(context, ref, 3),
                  ),
                  _DrawerTile(
                    icon: AppIcons.mistakesMode,
                    label: 'Yanlışlarım',
                    onTap: () =>
                        _openPage(context, ref, const MistakesListScreen()),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _DrawerTile(
                    icon: AppIcons.profile,
                    label: 'Profil',
                    onTap: () =>
                        _openPage(context, ref, const ProfileScreen()),
                  ),
                  _DrawerTile(
                    icon: AppIcons.settings,
                    label: 'Ayarlar',
                    onTap: () =>
                        _openPage(context, ref, const SettingsScreen()),
                  ),
                  _DrawerTile(
                    icon: AppIcons.info,
                    label: 'Hakkında',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 160),
                      );
                      if (!context.mounted) return;
                      await showAppInfoDialog(
                        context,
                        title: const KelimatikWordmark(fontSize: 22),
                        message:
                            'Türkçe yazımı oyunlaştıran modern uygulama.\n\nSürüm 1.0.0',
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.secondary,
                ),
                title: Text(
                  'Çıkış Yap',
                  style: AppTypography.body(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                onTap: () => _signOut(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: AppIcon(icon, size: 22),
          title: Text(
            label,
            style: AppTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.accentDeep : AppColors.textPrimary,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
