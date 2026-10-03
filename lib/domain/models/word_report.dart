/// Why a learner is flagging a spelling pair.
enum WordReportReason {
  wrongMarkedIsCorrect('wrong_marked_is_correct'),
  bothIncorrect('both_incorrect'),
  other('other');

  const WordReportReason(this.code);

  /// Stable value stored and emailed. Do not rename without a migration.
  final String code;

  String get label => switch (this) {
        WordReportReason.wrongMarkedIsCorrect =>
          'Yanlış diye işaretlenen yazım aslında doğru',
        WordReportReason.bothIncorrect => 'Her iki yazım da hatalı',
        WordReportReason.other => 'Başka bir sorun',
      };

  String? get subtitle => switch (this) {
        WordReportReason.wrongMarkedIsCorrect =>
          'TDK güncellemesi olabilir',
        WordReportReason.bothIncorrect || WordReportReason.other => null,
      };
}

/// Client-side rules mirrored by the database check.
abstract final class WordReportDraft {
  static const int maxNoteLength = 280;

  static bool canSubmit(WordReportReason? reason, String rawNote) {
    if (reason == null) return false;
    if (reason != WordReportReason.other) return true;
    final note = rawNote.trim();
    return note.isNotEmpty && note.length <= maxNoteLength;
  }

  /// Note sent to support. Null unless the reason is “other”.
  static String? noteForSubmit(WordReportReason reason, String rawNote) {
    if (reason != WordReportReason.other) return null;
    return rawNote.trim();
  }
}
