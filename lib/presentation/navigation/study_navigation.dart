import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/study_mode.dart';
import '../providers/lives_provider.dart';
import '../providers/quiz_provider.dart';
import '../screens/quiz_screen.dart';
import 'soft_transitions.dart';

Future<void> openStudySession(
  BuildContext context,
  WidgetRef ref,
  QuizSessionConfig config,
) async {
  if (config.consumeLives) {
    ref.read(livesProvider.notifier).refresh();
    if (!ref.read(livesProvider).canPlay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canın kalmadı. Biraz bekle veya ana ekrandan takip et.')),
      );
      return;
    }
  }

  await ref.read(quizProvider.notifier).startSession(config);
  if (!context.mounted) return;

  await pushSoft(context, const QuizScreen());
  ref.read(livesProvider.notifier).refresh();
}
