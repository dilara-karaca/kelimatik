import 'package:flutter_riverpod/flutter_riverpod.dart';

final mainTabIndexProvider =
    NotifierProvider<MainTabIndexNotifier, int>(MainTabIndexNotifier.new);

class MainTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}
