import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) consent gate for AdMob.
///
/// Call [gatherConsent] once per cold start before [AdMobBootstrap.initialize].
/// Failures never throw — the app continues and ads follow [canRequestAds].
abstract final class UmpConsentService {
  /// Soft cap so a stuck UMP call cannot freeze ad bootstrap forever.
  static const _timeout = Duration(seconds: 8);

  /// Optional hashed test device id (logcat / Xcode UMP message).
  /// Pass with: `--dart-define=UMP_TEST_DEVICE_ID=YOUR_HASH`
  static const _testDeviceId = String.fromEnvironment('UMP_TEST_DEVICE_ID');

  /// Updates consent info and shows the form only when UMP requires it.
  ///
  /// Already-valid choices are not re-prompted by the SDK.
  static Future<void> gatherConsent() async {
    final completer = Completer<void>();

    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    try {
      final params = ConsentRequestParameters(
        consentDebugSettings: _debugSettings,
      );

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
              if (formError != null) {
                debugPrint(
                  'UMP form error: ${formError.errorCode} ${formError.message}',
                );
              }
              finish();
            });
          } catch (e, st) {
            debugPrint('UMP load/show failed: $e\n$st');
            finish();
          }
        },
        (FormError error) {
          debugPrint(
            'UMP consent info update failed: ${error.errorCode} ${error.message}',
          );
          finish();
        },
      );
    } catch (e, st) {
      debugPrint('UMP unexpected failure: $e\n$st');
      finish();
    }

    try {
      await completer.future.timeout(_timeout);
    } on TimeoutException {
      debugPrint('UMP timed out after ${_timeout.inSeconds}s; continuing');
    }
  }

  /// Whether AdMob may request ads after consent handling.
  static Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e, st) {
      debugPrint('UMP canRequestAds failed: $e\n$st');
      // Fail open so a UMP glitch does not permanently kill ads.
      return true;
    }
  }

  /// Debug-only: treat device as EEA so the consent form can be exercised.
  /// Requires a test device hash for geography overrides to apply (see logs).
  static ConsentDebugSettings? get _debugSettings {
    if (!kDebugMode) return null;

    return ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
      testIdentifiers: _testDeviceId.isEmpty ? null : <String>[_testDeviceId],
    );
  }
}
