import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/domain/models/daily_streak_goal.dart';
import 'package:kelimatik/domain/models/daily_streak_state.dart';
import 'package:kelimatik/presentation/providers/catalog_providers.dart';
import 'package:kelimatik/presentation/screens/home_screen.dart';

void main() {
  final day = DateTime(2026, 10, 4);

  DailyStreakGoal goal({required int answered}) {
    return DailyStreakGoal(date: day, answered: answered);
  }

  testWidgets(
    'complete goal syncs once on open and again only when it changes',
    (tester) async {
      final streak = _CountingStreak();
      final goals = _MutableGoal(goal(answered: DailyStreakGoal.target));

      await tester.pumpWidget(
        _host(
          streak: streak,
          goals: goals,
          child: _RebuildHost(
            child: debugHomeStreakGoalSync(child: const SizedBox()),
          ),
        ),
      );

      expect(streak.syncs, 1);

      _RebuildHost.rebuild();
      await tester.pump();
      expect(streak.syncs, 1);

      goals.state = goal(answered: DailyStreakGoal.target + 1);
      await tester.pump();
      expect(streak.syncs, 2);

      _RebuildHost.rebuild();
      await tester.pump();
      expect(streak.syncs, 2);
    },
  );

  testWidgets('incomplete goal waits for a later completion', (tester) async {
    final streak = _CountingStreak();
    final goals = _MutableGoal(goal(answered: DailyStreakGoal.target - 1));

    await tester.pumpWidget(
      _host(
        streak: streak,
        goals: goals,
        child: debugHomeStreakGoalSync(child: const SizedBox()),
      ),
    );

    expect(streak.syncs, 0);

    goals.state = goal(answered: DailyStreakGoal.target);
    await tester.pump();
    expect(streak.syncs, 1);

    await tester.pump();
    expect(streak.syncs, 1);

    goals.state = goal(answered: 0);
    await tester.pump();
    expect(streak.syncs, 1);
  });
}

Widget _host({
  required _CountingStreak streak,
  required _MutableGoal goals,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      dailyStreakProvider.overrideWith(() => streak),
      dailyStreakGoalProvider.overrideWith(() => goals),
    ],
    child: MaterialApp(home: child),
  );
}

class _RebuildHost extends StatefulWidget {
  const _RebuildHost({required this.child});

  final Widget child;

  static late void Function() rebuild;

  @override
  State<_RebuildHost> createState() => _RebuildHostState();
}

class _RebuildHostState extends State<_RebuildHost> {
  @override
  Widget build(BuildContext context) {
    _RebuildHost.rebuild = () => setState(() {});
    return widget.child;
  }
}

class _CountingStreak extends DailyStreakNotifier {
  int syncs = 0;

  @override
  DailyStreakState build() => DailyStreakState.empty;

  @override
  Future<void> syncCompletedGoal({DateTime? now}) async {
    syncs += 1;
  }
}

class _MutableGoal extends DailyStreakGoalNotifier {
  _MutableGoal(this.initial);

  final DailyStreakGoal initial;

  @override
  DailyStreakGoal build() => initial;
}
