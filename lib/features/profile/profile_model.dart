/// App user profile stored in Supabase `public.profiles`.
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.xp,
    required this.level,
    required this.correctCount,
    required this.wrongCount,
    required this.streak,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int xp;
  final int level;
  final int correctCount;
  final int wrongCount;
  final int streak;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'xp': xp,
        'level': level,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'streak': streak,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? xp,
    int? level,
    int? correctCount,
    int? wrongCount,
    int? streak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
