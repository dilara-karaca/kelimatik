import '../../core/constants/app_characters.dart';
import '../../domain/models/daily_streak_state.dart';

/// App user profile stored in Supabase `public.profiles`.
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.selectedCharacter,
    required this.onboardingCompleted,
    required this.xp,
    required this.level,
    required this.correctCount,
    required this.wrongCount,
    required this.streak,
    required this.bestQuizStreak,
    required this.dailyStreak,
    required this.lastDailyLoginDate,
    required this.livesCurrent,
    required this.livesRegenStartedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? selectedCharacter;
  final bool onboardingCompleted;
  final int xp;
  final int level;
  final int correctCount;
  final int wrongCount;
  final int streak;
  final int bestQuizStreak;
  final int dailyStreak;
  final DateTime? lastDailyLoginDate;
  final int? livesCurrent;
  final DateTime? livesRegenStartedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Incomplete until flag is true and a known character id is stored.
  ///
  /// Missing DB columns deserialize as incomplete (not skipped).
  bool get needsOnboarding {
    if (!onboardingCompleted) return true;
    final character = selectedCharacter?.trim();
    if (character == null || character.isEmpty) return true;
    return !AppCharacters.isValidId(character);
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(Object? raw) {
      if (raw is! String || raw.isEmpty) return null;
      return DateTime.parse(raw).toLocal();
    }

    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      selectedCharacter: json['selected_character'] as String?,
      // Absent column (migration not applied) ⇒ incomplete ⇒ show onboarding.
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestQuizStreak: (json['best_quiz_streak'] as num?)?.toInt() ?? 0,
      dailyStreak: (json['daily_streak'] as num?)?.toInt() ?? 0,
      lastDailyLoginDate:
          DailyStreakState.parseDate(json['last_daily_login_date']),
      livesCurrent: (json['lives_current'] as num?)?.toInt(),
      livesRegenStartedAt: parseTs(json['lives_regen_started_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'selected_character': selectedCharacter,
        'onboarding_completed': onboardingCompleted,
        'xp': xp,
        'level': level,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'streak': streak,
        'best_quiz_streak': bestQuizStreak,
        'daily_streak': dailyStreak,
        'last_daily_login_date': lastDailyLoginDate == null
            ? null
            : DailyStreakState.formatDate(lastDailyLoginDate!),
        'lives_current': livesCurrent,
        'lives_regen_started_at':
            livesRegenStartedAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? selectedCharacter,
    bool? onboardingCompleted,
    int? xp,
    int? level,
    int? correctCount,
    int? wrongCount,
    int? streak,
    int? bestQuizStreak,
    int? dailyStreak,
    DateTime? lastDailyLoginDate,
    bool clearLastDailyLoginDate = false,
    int? livesCurrent,
    DateTime? livesRegenStartedAt,
    bool clearLivesRegenStartedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      streak: streak ?? this.streak,
      bestQuizStreak: bestQuizStreak ?? this.bestQuizStreak,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyLoginDate: clearLastDailyLoginDate
          ? null
          : (lastDailyLoginDate ?? this.lastDailyLoginDate),
      livesCurrent: livesCurrent ?? this.livesCurrent,
      livesRegenStartedAt: clearLivesRegenStartedAt
          ? null
          : (livesRegenStartedAt ?? this.livesRegenStartedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
