import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/core/constants/app_icons.dart';
import 'package:kelimatik/presentation/widgets/bomb_fuse_bar.dart';

void main() {
  testWidgets('renders the bomb asset for bomb mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BombFuseBar(
            cycle: 1,
            deadline: null,
            pausedMs: 0,
            exploding: false,
            frozen: false,
            onExplosionFinished: _noop,
          ),
        ),
      ),
    );

    expect(find.byType(BombFuseBar), findsOneWidget);
    expect(find.image(const AssetImage(AppIcons.bombFuse)), findsOneWidget);
  });
}

void _noop() {}
