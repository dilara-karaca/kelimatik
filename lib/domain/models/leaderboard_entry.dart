/// Leaderboard row — backend-agnostic so Supabase/Firebase can plug in later.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.score,
    this.characterId,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;

  /// Public handle shown on the board (e.g. `aysekara`).
  final String username;

  /// Fallback label when username is empty.
  final String displayName;
  final int score;

  /// Selected character asset id (`erkek1`, `kadin3`, …).
  final String? characterId;

  /// Highlights the signed-in player's row.
  final bool isCurrentUser;

  String get primaryName {
    final handle = username.trim();
    if (handle.isNotEmpty) return handle;
    final display = displayName.trim();
    if (display.isNotEmpty) return display;
    return 'oyuncu';
  }
}

abstract class LeaderboardRepository {
  /// Full ordered board (or top [limit] rows). Use a high limit for deep ranks.
  Future<List<LeaderboardEntry>> fetchTop({int limit = 500});
}
