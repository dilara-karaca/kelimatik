import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/main_tab_provider.dart';

/// Shared back / leave policies so destinations stay intentional.
///
/// Rules:
/// - Pushed screens (profil, ayarlar, yanlış listesi, kelime detay, quiz):
///   arrow back → previous route (origin).
/// - Quiz "Ana sayfaya dön" (can bitti): always land on Ana Sayfa tab.
/// - Bottom tabs: system/back from Ara/Favoriler/Sıralama → Ana Sayfa tab
///   (not app exit). From Ana Sayfa → allow system exit.
abstract final class AppNavigation {
  static const homeTab = 0;

  static bool canPop(BuildContext context) =>
      Navigator.of(context).canPop();

  /// Pops the current pushed route when possible.
  static void popRoute(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  /// Leaves a pushed flow and shows the home tab under the shell.
  static void leaveToHome(BuildContext context, WidgetRef ref) {
    ref.read(mainTabIndexProvider.notifier).setIndex(homeTab);
    popRoute(context);
  }

  /// Switches shell tab without pushing a route.
  static void goHomeTab(WidgetRef ref) {
    ref.read(mainTabIndexProvider.notifier).setIndex(homeTab);
  }
}
