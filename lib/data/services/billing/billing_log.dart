import 'package:flutter/foundation.dart';

/// Debug-only billing logs. Never prints purchase tokens or receipts.
void billingLog(String stage, [String? detail]) {
  if (!kDebugMode) return;
  if (detail == null || detail.isEmpty) {
    debugPrint('Billing: $stage');
    return;
  }
  debugPrint('Billing: $stage — $detail');
}
