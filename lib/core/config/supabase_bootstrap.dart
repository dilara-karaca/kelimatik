import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads `.env` and initializes the Supabase client.
///
/// Call once from [main] before [runApp].
abstract final class SupabaseBootstrap {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL']?.trim();
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

    if (url == null || url.isEmpty) {
      throw StateError(
        'SUPABASE_URL missing or empty. Copy .env.example to .env and fill values.',
      );
    }
    if (anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY missing or empty. Copy .env.example to .env and fill values.',
      );
    }

    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );
  }

  /// Shared client accessor for future auth/data layers.
  static SupabaseClient get client => Supabase.instance.client;
}
