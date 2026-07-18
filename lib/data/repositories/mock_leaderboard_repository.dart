import '../../domain/models/leaderboard_entry.dart';

/// Local fake leaderboard. Swap for Supabase/Firebase later.
class MockLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<LeaderboardEntry>> fetchTop({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final mock = const [
      LeaderboardEntry(
        rank: 1,
        userId: 'u1',
        displayName: 'Ayşe K.',
        score: 18420,
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 'u2',
        displayName: 'Can Y.',
        score: 17110,
      ),
      LeaderboardEntry(
        rank: 3,
        userId: 'u3',
        displayName: 'Elif D.',
        score: 16540,
      ),
      LeaderboardEntry(
        rank: 4,
        userId: 'u4',
        displayName: 'Mert S.',
        score: 15200,
      ),
      LeaderboardEntry(
        rank: 5,
        userId: 'u5',
        displayName: 'Zeynep A.',
        score: 14880,
      ),
      LeaderboardEntry(
        rank: 6,
        userId: 'u6',
        displayName: 'Emre T.',
        score: 13990,
      ),
      LeaderboardEntry(
        rank: 7,
        userId: 'u7',
        displayName: 'Selin B.',
        score: 13250,
      ),
      LeaderboardEntry(
        rank: 8,
        userId: 'u8',
        displayName: 'Deniz K.',
        score: 12100,
      ),
      LeaderboardEntry(
        rank: 9,
        userId: 'u9',
        displayName: 'Burak M.',
        score: 11840,
      ),
      LeaderboardEntry(
        rank: 10,
        userId: 'u10',
        displayName: 'İrem N.',
        score: 10970,
      ),
    ];
    return mock.take(limit).toList();
  }
}
