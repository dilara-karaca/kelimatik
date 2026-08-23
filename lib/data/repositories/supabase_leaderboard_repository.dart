import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_characters.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/leaderboard_entry.dart';

/// Leaderboard from `public.profiles` ordered by XP / correct answers.
class SupabaseLeaderboardRepository implements LeaderboardRepository {
  SupabaseLeaderboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<LeaderboardEntry>> fetchTop({int limit = 500}) async {
    final rows = await _client
        .from('profiles')
        .select(
          'id, username, display_name, xp, correct_count, selected_character, onboarding_completed',
        )
        .eq('onboarding_completed', true)
        .order('xp', ascending: false)
        .order('correct_count', ascending: false)
        .limit(limit);

    final uid = _client.auth.currentUser?.id;
    final list = (rows as List<dynamic>)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();

    return [
      for (var i = 0; i < list.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          userId: list[i]['id'] as String,
          username: (list[i]['username'] as String?)?.trim() ?? '',
          displayName: _displayName(list[i]),
          score: _score(list[i]),
          characterId: _characterId(list[i]['selected_character']),
          isCurrentUser: uid != null && uid == list[i]['id'],
        ),
    ];
  }

  /// Prefer stored [xp]; if an older 1:1 row still has xp == correct_count,
  /// show the new scale so ranking stays consistent until next progress sync.
  int _score(Map<String, dynamic> row) {
    final xp = (row['xp'] as num?)?.toInt() ?? 0;
    final correct = (row['correct_count'] as num?)?.toInt() ?? 0;
    final fromCorrect =
        (correct * AppConstants.xpPerCorrectAnswer).clamp(0, 1 << 30);
    if (correct > 0 && xp == correct) return fromCorrect;
    return xp < 0 ? 0 : xp;
  }

  String? _characterId(Object? raw) {
    if (raw is! String) return null;
    final id = raw.trim();
    if (id.isEmpty || !AppCharacters.isValidId(id)) return null;
    return id;
  }

  String _displayName(Map<String, dynamic> row) {
    final display = (row['display_name'] as String?)?.trim();
    if (display != null && display.isNotEmpty) return display;
    return row['username'] as String? ?? 'Oyuncu';
  }
}
