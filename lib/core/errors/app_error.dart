/// Classifies failures into user-facing error states.
enum AppErrorKind {
  offline,
  loadFailed,
  generic,
}

/// Title + message for empty/error screens.
class AppErrorInfo {
  const AppErrorInfo({
    required this.kind,
    required this.title,
    required this.message,
  });

  final AppErrorKind kind;
  final String title;
  final String message;

  static const offline = AppErrorInfo(
    kind: AppErrorKind.offline,
    title: 'İnternet yok',
    message: 'İnternet bağlantını kontrol et.',
  );

  static const loadFailed = AppErrorInfo(
    kind: AppErrorKind.loadFailed,
    title: 'Veri yüklenemedi',
    message: 'Verileri yükleyemedik.\nTekrar dene.',
  );

  static const generic = AppErrorInfo(
    kind: AppErrorKind.generic,
    title: 'Bir sorun oluştu',
    message: 'Beklenmeyen bir hata oluştu.\nTekrar dene.',
  );

  /// Maps exceptions / async errors to a stable UI state.
  factory AppErrorInfo.from(Object? error) {
    if (error is AppErrorInfo) return error;
    final text = error?.toString().toLowerCase() ?? '';
    if (_looksOffline(text)) return offline;
    if (text.contains('yüklen') ||
        text.contains('load') ||
        text.contains('fetch') ||
        text.contains('timeout') ||
        text.contains('postgrest') ||
        text.contains('supabase')) {
      return loadFailed;
    }
    if (text.trim().isEmpty || text == 'null' || text.contains('exception')) {
      return loadFailed;
    }
    return loadFailed;
  }

  static bool _looksOffline(String text) {
    return text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('failed host lookup') ||
        text.contains('nodename nor servname') ||
        text.contains('name not resolved') ||
        text.contains('no address associated') ||
        text.contains('nxdomain') ||
        text.contains('offline') ||
        text.contains('internet') ||
        text.contains('clientexception') ||
        text.contains('connection closed') ||
        text.contains('connection reset');
  }
}
