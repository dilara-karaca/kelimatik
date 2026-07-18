/// A single correct/wrong spelling pair loaded from JSON.
class WordPair {
  const WordPair({
    required this.id,
    required this.correct,
    required this.wrong,
    this.example,
  });

  final int id;
  final String correct;
  final String wrong;

  /// Optional sample usage sentence from data; may be null.
  final String? example;

  /// Ready-to-show usage for detail screens.
  String get usageExample {
    final custom = example?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return 'Doğru kullanım: «$correct». '
        'Sık yapılan yanlış yazım ise «$wrong» biçimidir.';
  }

  factory WordPair.fromJson(Map<String, dynamic> json) {
    return WordPair(
      id: json['id'] as int,
      correct: json['correct'] as String,
      wrong: json['wrong'] as String,
      example: json['example'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'correct': correct,
        'wrong': wrong,
        if (example != null) 'example': example,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordPair &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
