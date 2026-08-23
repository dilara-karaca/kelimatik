import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/study_mode.dart';
import '../providers/lives_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/quiz_provider.dart';
import '../screens/premium_screen.dart';
import '../screens/quiz_screen.dart';
import '../widgets/out_of_lives_entry_dialog.dart';
import 'soft_transitions.dart';

Future<void> openStudySession(
  BuildContext context,
  WidgetRef ref,
  QuizSessionConfig config,
) async {
  final isPremium = ref.read(premiumProvider);

  if (config.consumeLives && !isPremium) {
    ref.read(livesProvider.notifier).refresh();
    if (!ref.read(livesProvider).canPlay) {
      final result = await showOutOfLivesEntryDialog(context, ref);
      if (!context.mounted) return;

      if (result == OutOfLivesEntryResult.openPremium) {
        await pushSoft(context, const PremiumScreen());
        return;
      }
      if (result != OutOfLivesEntryResult.lifeGained) return;

      ref.read(livesProvider.notifier).refresh();
      if (!ref.read(livesProvider).canPlay) return;
    }
  }

  await ref.read(quizProvider.notifier).startSession(config);
  if (!context.mounted) return;

  await pushSoft(context, const QuizScreen());
  ref.read(livesProvider.notifier).refresh();
}
