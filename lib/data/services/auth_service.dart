import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/auth_failure.dart';

/// Google Sign-In via native SDK, then Supabase session via ID token.
///
/// No email/password. Sign-out is implemented for later UI wiring.
class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleReady = false;

  static const _scopes = ['email', 'profile'];

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  bool get isSignedIn => currentSession != null;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Refreshes the persisted session so JWT is valid before data queries.
  ///
  /// Returns the current session when refresh is unnecessary or unavailable.
  Future<Session?> ensureFreshSession() async {
    final session = currentSession;
    if (session == null) return null;

    final expiresAt = session.expiresAt;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Still valid for >60s — no need to hit the network.
    if (expiresAt != null && expiresAt - nowSec > 60) {
      return session;
    }

    try {
      final response = await _client.auth.refreshSession();
      return response.session ?? currentSession;
    } on AuthException {
      // Keep local session; profile layer will surface a clear error / retry.
      return currentSession;
    } catch (_) {
      return currentSession;
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleReady) return;

    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (webClientId == null ||
        webClientId.isEmpty ||
        webClientId.contains('YOUR_WEB_CLIENT_ID') ||
        !webClientId.endsWith('.apps.googleusercontent.com')) {
      throw const AuthFailure(
        'GOOGLE_WEB_CLIENT_ID eksik veya geçersiz. '
        'Google Cloud → Web OAuth Client ID değerini .env dosyasına yaz '
        '(Android Client ID değil).',
      );
    }

    try {
      await _googleSignIn.initialize(serverClientId: webClientId);
      _googleReady = true;
    } on GoogleSignInException catch (error) {
      throw AuthFailure(_mapGoogleError(error));
    } catch (error) {
      throw AuthFailure(_mapError(error));
    }
  }

  /// Opens native Google account picker and creates a Supabase session.
  Future<AuthResponse> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    try {
      final googleUser = await _googleSignIn.authenticate();

      final authorization = await googleUser.authorizationClient
              .authorizationForScopes(_scopes) ??
          await googleUser.authorizationClient.authorizeScopes(_scopes);

      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          'Google kimlik doğrulaması tamamlanamadı. ID token alınamadı.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      if (response.session == null) {
        throw const AuthFailure('Oturum oluşturulamadı. Lütfen tekrar dene.');
      }

      return response;
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AuthFailure(_mapSupabaseAuthError(error));
    } on GoogleSignInException catch (error) {
      throw AuthFailure(_mapGoogleError(error));
    } catch (error) {
      throw AuthFailure(_mapError(error));
    }
  }

  /// Clears Google + Supabase sessions (local fallback if network hangs).
  Future<void> signOut() async {
    try {
      if (_googleReady) {
        await _googleSignIn.signOut().timeout(const Duration(seconds: 3));
      }
    } catch (_) {
      // Still clear Supabase session even if Google sign-out fails.
    }

    try {
      await _client.auth
          .signOut()
          .timeout(const Duration(seconds: 5));
    } on AuthException catch (error) {
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        throw AuthFailure(_mapSupabaseAuthError(error));
      }
    } catch (_) {
      // Prefer clearing local session so the UI can return to login.
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } catch (error) {
        throw AuthFailure(_mapError(error));
      }
    }
  }

  /// Permanently deletes the signed-in Auth user and cascaded DB data.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailure('Oturum bulunamadı. Tekrar giriş yap.');
    }

    try {
      await _client.rpc('delete_own_account');
    } on PostgrestException catch (error) {
      throw AuthFailure(
        error.message.trim().isEmpty
            ? 'Hesap silinemedi. Lütfen tekrar dene.'
            : 'Hesap silinemedi: ${error.message}',
      );
    } on AuthException catch (error) {
      throw AuthFailure(_mapSupabaseAuthError(error));
    } catch (error) {
      throw AuthFailure(_mapError(error));
    }

    // Clear local sessions even if the server already invalidated the JWT.
    try {
      await signOut();
    } catch (_) {
      // Account is already gone; force local cleanup below if needed.
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
    }
  }

  String _mapGoogleError(GoogleSignInException error) {
    final detail = error.description?.trim();
    final detailSuffix =
        (detail != null && detail.isNotEmpty) ? ' ($detail)' : '';

    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        // Misconfigured OAuth often surfaces as "canceled" on Android.
        return 'Google girişi tamamlanamadı. '
            'Web Client ID, Android Client (package + SHA-1) ve '
            'test kullanıcısı ayarlarını kontrol et.$detailSuffix';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google girişi yarıda kesildi. Tekrar dene.$detailSuffix';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google giriş ayarı hatalı. '
            '.env içindeki GOOGLE_WEB_CLIENT_ID Web Client ID olmalı; '
            'Android OAuth client’ta package name ve SHA-1 doğru olmalı.$detailSuffix';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sağlayıcı yapılandırması hatalı.$detailSuffix';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google giriş ekranı açılamadı.$detailSuffix';
      default:
        return 'Google ile giriş başarısız oldu.$detailSuffix';
    }
  }

  String _mapSupabaseAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (_looksLikeHostLookupFailure(message)) {
      return 'Supabase sunucusuna ulaşılamadı. '
          '.env içindeki SUPABASE_URL değerini kontrol et.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'İnternet bağlantını kontrol edip tekrar dene.';
    }
    if (message.contains('id token') || message.contains('audience')) {
      return 'Google kimliği doğrulanamadı. Supabase Google ayarlarını kontrol et.';
    }
    return 'Giriş başarısız: ${error.message}';
  }

  String _mapError(Object error) {
    final text = error.toString().toLowerCase();
    if (_looksLikeHostLookupFailure(text)) {
      return 'Supabase sunucusuna ulaşılamadı. '
          '.env içindeki SUPABASE_URL değerini kontrol et.';
    }
    if (text.contains('network') || text.contains('socket')) {
      return 'İnternet bağlantını kontrol edip tekrar dene.';
    }
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.';
  }

  bool _looksLikeHostLookupFailure(String text) {
    return text.contains('failed host lookup') ||
        text.contains('nodename nor servname') ||
        text.contains('name not resolved') ||
        text.contains('no address associated') ||
        text.contains('nxdomain');
  }
}
