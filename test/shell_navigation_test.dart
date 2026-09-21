import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/presentation/navigation/soft_transitions.dart';

void main() {
  testWidgets('pushSoft stays inside the shell so the bottom bar remains',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _ShellHost(),
      ),
    );

    await tester.tap(find.text('open-shell'));
    await tester.pumpAndSettle();

    expect(find.text('pushed-page'), findsOneWidget);
    expect(find.text('bottom-bar'), findsOneWidget);
  });

  testWidgets('pushSoftFullscreen covers the shell bottom bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _ShellHost(),
      ),
    );

    await tester.tap(find.text('open-full'));
    await tester.pumpAndSettle();

    expect(find.text('pushed-page'), findsOneWidget);
    expect(find.text('bottom-bar'), findsNothing);
  });
}

class _ShellHost extends StatelessWidget {
  const _ShellHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () => pushSoft(
                      context,
                      const Scaffold(body: Text('pushed-page')),
                    ),
                    child: const Text('open-shell'),
                  ),
                  TextButton(
                    onPressed: () => pushSoftFullscreen(
                      context,
                      const Scaffold(body: Text('pushed-page')),
                    ),
                    child: const Text('open-full'),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: const Text('bottom-bar'),
    );
  }
}
