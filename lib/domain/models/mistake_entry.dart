/// Persistence model for missed words — spaced-repetition ready.
class MistakeEntry {
  const MistakeEntry({
    required this.wordId,
    required this.wrongCount,
    required this.correctSinceMissCount,
    required this.firstMissedAt,
    required this.lastMissedAt,
    this.lastCorrectAt,
    this.easiness = 2.5,
    this.intervalDays = 0,
    this.repetition = 0,
  });

  final int wordId;
  final int wrongCount;

  /// Correct answers after the last miss (for future SRS graduation rules).
  final int correctSinceMissCount;
  final DateTime firstMissedAt;
  final DateTime lastMissedAt;
  final DateTime? lastCorrectAt;

  /// SM-2 style fields reserved for a future spaced-repetition engine.
  final double easiness;
  final int intervalDays;
  final int repetition;

  MistakeEntry recordWrong([DateTime? at]) {
    final now = at ?? DateTime.now();
    return MistakeEntry(
      wordId: wordId,
      wrongCount: wrongCount + 1,
      correctSinceMissCount: 0,
      firstMissedAt: firstMissedAt,
      lastMissedAt: now,
      lastCorrectAt: lastCorrectAt,
      easiness: easiness,
      intervalDays: intervalDays,
      repetition: repetition,
    );
  }

  MistakeEntry recordCorrect([DateTime? at]) {
    final now = at ?? DateTime.now();
    return MistakeEntry(
      wordId: wordId,
      wrongCount: wrongCount,
      correctSinceMissCount: correctSinceMissCount + 1,
      firstMissedAt: firstMissedAt,
      lastMissedAt: lastMissedAt,
      lastCorrectAt: now,
      easiness: easiness,
      intervalDays: intervalDays,
      repetition: repetition,
    );
  }

  factory MistakeEntry.firstMiss(int wordId, [DateTime? at]) {
    final now = at ?? DateTime.now();
    return MistakeEntry(
      wordId: wordId,
      wrongCount: 1,
      correctSinceMissCount: 0,
      firstMissedAt: now,
      lastMissedAt: now,
    );
  }

  factory MistakeEntry.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    return MistakeEntry(
      wordId: asInt(json['wordId']),
      wrongCount: asInt(json['wrongCount'], 1),
      correctSinceMissCount: asInt(json['correctSinceMissCount']),
      firstMissedAt: DateTime.fromMillisecondsSinceEpoch(
        asInt(json['firstMissedAt']),
      ),
      lastMissedAt: DateTime.fromMillisecondsSinceEpoch(
        asInt(json['lastMissedAt']),
      ),
      lastCorrectAt: json['lastCorrectAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(asInt(json['lastCorrectAt'])),
      easiness: (json['easiness'] as num?)?.toDouble() ?? 2.5,
      intervalDays: asInt(json['intervalDays']),
      repetition: asInt(json['repetition']),
    );
  }

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'wrongCount': wrongCount,
        'correctSinceMissCount': correctSinceMissCount,
        'firstMissedAt': firstMissedAt.millisecondsSinceEpoch,
        'lastMissedAt': lastMissedAt.millisecondsSinceEpoch,
        'lastCorrectAt': lastCorrectAt?.millisecondsSinceEpoch,
        'easiness': easiness,
        'intervalDays': intervalDays,
        'repetition': repetition,
      };
}
