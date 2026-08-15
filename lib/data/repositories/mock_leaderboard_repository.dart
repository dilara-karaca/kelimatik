import '../../core/constants/app_characters.dart';
import '../../domain/models/leaderboard_entry.dart';

/// Temporary mock board so the UI can be reviewed with filled rows.
///
/// Swap [leaderboardRepositoryProvider] back to Supabase when ready.
class MockLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<LeaderboardEntry>> fetchTop({int limit = 500}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _seed.take(limit).toList();
  }

  static const _seed = <LeaderboardEntry>[
    LeaderboardEntry(
      rank: 1,
      userId: 'm1',
      username: 'aysekara',
      displayName: 'Ayşe Kara',
      score: 18420,
      characterId: 'kadin1',
      isCurrentUser: true,
    ),
    LeaderboardEntry(
      rank: 2,
      userId: 'm2',
      username: 'canyilmaz',
      displayName: 'Can Yılmaz',
      score: 17110,
      characterId: 'erkek2',
    ),
    LeaderboardEntry(
      rank: 3,
      userId: 'm3',
      username: 'elifdemir',
      displayName: 'Elif Demir',
      score: 16540,
      characterId: 'kadin3',
    ),
    LeaderboardEntry(
      rank: 4,
      userId: 'm4',
      username: 'mertsoy',
      displayName: 'Mert Soy',
      score: 15200,
      characterId: 'erkek1',
    ),
    LeaderboardEntry(
      rank: 5,
      userId: 'm5',
      username: 'zeynepak',
      displayName: 'Zeynep Ak',
      score: 14880,
      characterId: 'kadin2',
    ),
    LeaderboardEntry(
      rank: 6,
      userId: 'm6',
      username: 'emreturk',
      displayName: 'Emre Türk',
      score: 13990,
      characterId: 'erkek3',
    ),
    LeaderboardEntry(
      rank: 7,
      userId: 'm7',
      username: 'selinbay',
      displayName: 'Selin Bay',
      score: 13250,
      characterId: 'kadin4',
    ),
    LeaderboardEntry(
      rank: 8,
      userId: 'm8',
      username: 'denizkaya',
      displayName: 'Deniz Kaya',
      score: 12100,
      characterId: 'erkek4',
    ),
    LeaderboardEntry(
      rank: 9,
      userId: 'm9',
      username: 'burakm',
      displayName: 'Burak M.',
      score: 11840,
      characterId: 'erkek5',
    ),
    LeaderboardEntry(
      rank: 10,
      userId: 'm10',
      username: 'iremnil',
      displayName: 'İrem Nil',
      score: 10970,
      characterId: 'kadin5',
    ),
    LeaderboardEntry(
      rank: 11,
      userId: 'm11',
      username: 'onurk',
      displayName: 'Onur K.',
      score: 9800,
      characterId: 'erkek1',
    ),
    LeaderboardEntry(
      rank: 12,
      userId: 'm12',
      username: 'melisay',
      displayName: 'Melisa Y.',
      score: 9120,
      characterId: 'kadin1',
    ),
    LeaderboardEntry(
      rank: 13,
      userId: 'm13',
      username: 'berkayo',
      displayName: 'Berkay O.',
      score: 8640,
      characterId: 'erkek2',
    ),
    LeaderboardEntry(
      rank: 14,
      userId: 'm14',
      username: 'defnea',
      displayName: 'Defne A.',
      score: 7990,
      characterId: 'kadin3',
    ),
    LeaderboardEntry(
      rank: 15,
      userId: 'm15',
      username: 'keremt',
      displayName: 'Kerems T.',
      score: 7350,
      characterId: 'erkek3',
    ),
    LeaderboardEntry(
      rank: 16,
      userId: 'm16',
      username: 'gizemc',
      displayName: 'Gizem C.',
      score: 6810,
      characterId: 'kadin2',
    ),
    LeaderboardEntry(
      rank: 17,
      userId: 'm17',
      username: 'alperen',
      displayName: 'Alperen',
      score: 6240,
      characterId: 'erkek4',
    ),
    LeaderboardEntry(
      rank: 18,
      userId: 'm18',
      username: 'yaseminn',
      displayName: 'Yasemin',
      score: 5580,
      characterId: 'kadin4',
    ),
  ];

  /// Ensures mock character ids stay valid against [AppCharacters].
  static bool get seedUsesValidCharacters => _seed.every(
        (e) =>
            e.characterId == null || AppCharacters.isValidId(e.characterId!),
      );
}
