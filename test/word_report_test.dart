import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/data/services/word_report_service.dart';
import 'package:kelimatik/domain/models/word_report.dart';

void main() {
  group('WordReportDraft', () {
    test('requires a reason', () {
      expect(WordReportDraft.canSubmit(null, ''), isFalse);
    });

    test('preset reasons do not need a note', () {
      expect(
        WordReportDraft.canSubmit(WordReportReason.wrongMarkedIsCorrect, ''),
        isTrue,
      );
      expect(
        WordReportDraft.canSubmit(WordReportReason.bothIncorrect, '  '),
        isTrue,
      );
      expect(
        WordReportDraft.noteForSubmit(
          WordReportReason.bothIncorrect,
          'not gönderilmesin',
        ),
        isNull,
      );
    });

    test('other requires a trimmed note within the limit', () {
      expect(WordReportDraft.canSubmit(WordReportReason.other, '  '), isFalse);
      expect(
        WordReportDraft.canSubmit(WordReportReason.other, 'yazım değişmiş'),
        isTrue,
      );
      expect(
        WordReportDraft.noteForSubmit(
          WordReportReason.other,
          '  yazım değişmiş  ',
        ),
        'yazım değişmiş',
      );
      expect(
        WordReportDraft.canSubmit(
          WordReportReason.other,
          'a' * (WordReportDraft.maxNoteLength + 1),
        ),
        isFalse,
      );
    });
  });

  group('wordReportFailureFromFunction', () {
    test('maps support responses', () {
      expect(
        wordReportFailureFromFunction(429, {'error': 'rate_limited'}),
        WordReportFailure.rateLimited,
      );
      expect(
        wordReportFailureFromFunction(401, {'error': 'auth'}),
        WordReportFailure.auth,
      );
      expect(
        wordReportFailureFromFunction(400, {'error': 'invalid'}),
        WordReportFailure.invalid,
      );
      expect(
        wordReportFailureFromFunction(502, {'error': 'unavailable'}),
        WordReportFailure.unavailable,
      );
    });
  });
}
