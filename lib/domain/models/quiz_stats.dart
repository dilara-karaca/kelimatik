/// Aggregated quiz statistics — designed for future expansion.
class QuizStats {
  const QuizStats({
    this.totalCorrect = 0,
    this.totalWrong = 0,
  });

  final int totalCorrect;
  final int totalWrong;

  int get totalAnswered => totalCorrect + totalWrong;

  double get successRate {
    if (totalAnswered == 0) return 0;
    return (totalCorrect / totalAnswered) * 100;
  }

  QuizStats copyWith({
    int? totalCorrect,
    int? totalWrong,
  }) {
    return QuizStats(
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalWrong: totalWrong ?? this.totalWrong,
    );
  }

  QuizStats recordCorrect() => copyWith(totalCorrect: totalCorrect + 1);

  QuizStats recordWrong() => copyWith(totalWrong: totalWrong + 1);

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalWrong: json['totalWrong'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
      };

  static const empty = QuizStats();
}
