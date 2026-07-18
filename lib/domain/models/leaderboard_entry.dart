/// Leaderboard row — backend-agnostic so Supabase/Firebase can plug in later.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
  });

  final int rank;
  final String userId;
  final String displayName;
  final int score;
}

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> fetchTop({int limit = 20});
}
