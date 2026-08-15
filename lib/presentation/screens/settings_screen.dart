import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../navigation/app_navigation.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_icon.dart';
import '../widgets/kelimatik_wordmark.dart';
import '../widgets/playful_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => AppNavigation.popRoute(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text('Ayarlar', style: AppTypography.brand(fontSize: 24)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Text(
                      'Deneyim',
                      style: AppTypography.title(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          secondary:
                              const AppIcon(AppIcons.notification, size: 22),
                          title: Text(
                            'Bildirimler',
                            style: AppTypography.body(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Hatırlatmalar için tercih (yerel)',
                            style: AppTypography.title(fontSize: 12),
                          ),
                          value: settings.notificationsEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationsEnabled(v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          secondary: const Icon(
                            Icons.vibration_rounded,
                            size: 22,
                            color: AppColors.textPrimary,
                          ),
                          title: Text(
                            'Titreşim',
                            style: AppTypography.body(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Doğru / yanlış cevap geri bildirimi',
                            style: AppTypography.title(fontSize: 12),
                          ),
                          value: settings.hapticsEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setHapticsEnabled(v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Hakkında',
                      style: AppTypography.title(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        ListTile(
                          leading: const AppIcon(AppIcons.info, size: 22),
                          title: Text(
                            'Kelimatik hakkında',
                            style: AppTypography.body(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Türkçe yazımı oyunlaştıran modern uygulama.',
                            style: AppTypography.title(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showAbout(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Hesap',
                      style: AppTypography.title(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.secondary,
                          ),
                          title: Text(
                            'Çıkış Yap',
                            style: AppTypography.body(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.secondary,
                            ),
                          ),
                          onTap: () => _confirmSignOut(context, ref),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_forever_rounded,
                            color: AppColors.wrong,
                          ),
                          title: Text(
                            'Hesabı Sil',
                            style: AppTypography.body(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.wrong,
                            ),
                          ),
                          subtitle: Text(
                            'Tüm ilerleme ve veriler kalıcı olarak silinir',
                            style: AppTypography.title(fontSize: 12),
                          ),
                          onTap: () => _confirmDeleteAccount(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Center(child: KelimatikWordmark(fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    await showAppInfoDialog(
      context,
      title: const KelimatikWordmark(fontSize: 22),
      message:
          'Türkçe yazımı oyunlaştıran modern uygulama.\n\nSürüm 1.0.0',
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Çıkış Yap',
      message: 'Hesabından çıkmak istediğine emin misin?',
      confirmLabel: 'Çıkış Yap',
      destructive: true,
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Hesabı Sil',
      message:
          'Bu işlem geri alınamaz.\n\nProfilin, favorilerin, yanlışların, '
          'canların, serin ve tüm ilerleme verilerin kalıcı olarak silinir.',
      confirmLabel: 'Hesabı Sil',
      destructive: true,
    );
    if (confirmed != true) return;

    final error = await ref.read(authProvider.notifier).deleteAccount();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
