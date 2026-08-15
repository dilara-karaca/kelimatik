enum StudyMode {
  classic,
  challenge,
  mistakes,
  streak,
  infinite,
  favorites,
}

/// Configures a quiz session. Modes share one QuizNotifier pipeline.
class QuizSessionConfig {
  const QuizSessionConfig({
    required this.mode,
    this.timeLimit,
    this.targetCount,
    this.consumeLives = true,
    this.endOnFirstWrong = false,
    this.recordMistakes = true,
    this.endWhenDeckComplete = false,
  });

  final StudyMode mode;
  final Duration? timeLimit;
  final int? targetCount;
  final bool consumeLives;
  final bool endOnFirstWrong;
  final bool recordMistakes;

  /// When true, finishing the shuffled deck ends the session (no reshuffle).
  final bool endWhenDeckComplete;

  factory QuizSessionConfig.classic() => const QuizSessionConfig(
        mode: StudyMode.classic,
      );

  factory QuizSessionConfig.infinite() => const QuizSessionConfig(
        mode: StudyMode.infinite,
      );

  factory QuizSessionConfig.mistakes() => const QuizSessionConfig(
        mode: StudyMode.mistakes,
      );

  factory QuizSessionConfig.favorites() => const QuizSessionConfig(
        mode: StudyMode.favorites,
        endWhenDeckComplete: true,
      );

  factory QuizSessionConfig.streak() => const QuizSessionConfig(
        mode: StudyMode.streak,
        consumeLives: false,
        endOnFirstWrong: true,
      );

  factory QuizSessionConfig.challenge({
    Duration? timeLimit,
    int? targetCount,
  }) {
    assert(timeLimit != null || targetCount != null);
    return QuizSessionConfig(
      mode: StudyMode.challenge,
      timeLimit: timeLimit,
      targetCount: targetCount,
      consumeLives: false,
    );
  }

  String get title {
    switch (mode) {
      case StudyMode.classic:
        return 'Klasik Mod';
      case StudyMode.challenge:
        return 'Challenge';
      case StudyMode.mistakes:
        return 'Yanlışlarım';
      case StudyMode.streak:
        return 'Seri Modu';
      case StudyMode.infinite:
        return 'Sonsuz Mod';
      case StudyMode.favorites:
        return 'Favoriler';
    }
  }
}

class QuizSessionResult {
  const QuizSessionResult({
    required this.mode,
    required this.correct,
    required this.wrong,
    required this.answered,
    required this.elapsed,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  final StudyMode mode;
  final int correct;
  final int wrong;
  final int answered;
  final Duration elapsed;
  final int currentStreak;
  final int bestStreak;

  double get successRate {
    if (answered == 0) return 0;
    return (correct / answered) * 100;
  }

  String get elapsedLabel {
    final total = elapsed.inSeconds.clamp(0, 24 * 3600);
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Ready-made challenge packages shown in the bottom sheet.
class ChallengePackage {
  const ChallengePackage({
    required this.id,
    required this.title,
    required this.subtitle,
    this.timeLimit,
    this.targetCount,
  });

  final String id;
  final String title;
  final String subtitle;
  final Duration? timeLimit;
  final int? targetCount;

  QuizSessionConfig toConfig() => QuizSessionConfig.challenge(
        timeLimit: timeLimit,
        targetCount: targetCount,
      );
}

abstract final class ChallengePresets {
  static const packages = <ChallengePackage>[
    ChallengePackage(
      id: 'hizli',
      title: 'Hızlı',
      subtitle: '1 dakika — mümkün olduğunca çok doğru',
      timeLimit: Duration(minutes: 1),
    ),
    ChallengePackage(
      id: 'standart',
      title: 'Standart',
      subtitle: '3 dakika — dengeli tempo',
      timeLimit: Duration(minutes: 3),
    ),
    ChallengePackage(
      id: 'sprint',
      title: 'Sprint',
      subtitle: '20 kelime — kısa ve net',
      targetCount: 20,
    ),
    ChallengePackage(
      id: 'maraton',
      title: 'Maraton',
      subtitle: '50 kelime — dayanıklılık testi',
      targetCount: 50,
    ),
  ];
}

abstract final class FeaturePrefsKeys {
  static const mistakes = 'quiz_mistakes_v1';
  static const favorites = 'quiz_favorites_v1';
  static const streakBest = 'quiz_streak_best';
  static const dailyStreak = 'quiz_daily_streak';
  static const dailyStreakLastDate = 'quiz_daily_streak_last_date';
  static const displayName = 'display_name';
  static const hapticsEnabled = 'settings_haptics_enabled';
  static const notificationsEnabled = 'settings_notifications_enabled';
}
