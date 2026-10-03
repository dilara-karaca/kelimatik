import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/word_pair.dart';
import '../../domain/models/word_report.dart';

enum WordReportFailure implements Exception {
  invalid,
  rateLimited,
  auth,
  offline,
  unavailable;

  String get message => switch (this) {
        WordReportFailure.rateLimited =>
          'Bugün çok fazla bildirim gönderdin. Yarın tekrar dene.',
        WordReportFailure.auth =>
          'Oturumun kapandı. Tekrar giriş yapıp dene.',
        WordReportFailure.offline => 'İnternet bağlantını kontrol et.',
        WordReportFailure.invalid || WordReportFailure.unavailable =>
          'Bildirim gönderilemedi. Biraz sonra tekrar dene.',
      };
}

/// Sends a word report through the `report-word` edge function.
///
/// The function stores the row and emails kelimatik.support@gmail.com.
/// The device mail app is never opened.
class WordReportService {
  WordReportService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submit({
    required WordPair word,
    required WordReportReason reason,
    String note = '',
  }) async {
    if (!WordReportDraft.canSubmit(reason, note)) {
      throw WordReportFailure.invalid;
    }

    try {
      final response = await _client.functions.invoke(
        'report-word',
        body: {
          'word_id': word.id,
          'correct': word.correct,
          'wrong': word.wrong,
          'reason': reason.code,
          'note': WordReportDraft.noteForSubmit(reason, note),
        },
      );
      final data = response.data;
      if (data is Map && data['ok'] == true) return;
      throw WordReportFailure.unavailable;
    } on WordReportFailure {
      rethrow;
    } on FunctionException catch (error) {
      throw wordReportFailureFromFunction(error.status, error.details);
    } catch (error) {
      throw wordReportFailureFromThrown(error);
    }
  }
}

WordReportFailure wordReportFailureFromFunction(int status, Object? details) {
  final code = _errorCode(details);
  if (code == 'rate_limited' || status == 429) {
    return WordReportFailure.rateLimited;
  }
  if (code == 'auth' || status == 401) return WordReportFailure.auth;
  if (code == 'invalid' || status == 400) return WordReportFailure.invalid;
  return WordReportFailure.unavailable;
}

WordReportFailure wordReportFailureFromThrown(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('connection') ||
      text.contains('failed host lookup') ||
      text.contains('offline') ||
      text.contains('clientexception')) {
    return WordReportFailure.offline;
  }
  return WordReportFailure.unavailable;
}

String? _errorCode(Object? details) {
  if (details is Map) {
    final code = details['error'];
    if (code is String) return code;
  }
  if (details is String && details.isNotEmpty) return details;
  return null;
}
