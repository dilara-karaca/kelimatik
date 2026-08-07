import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/navigation/soft_transitions.dart';
import 'presentation/widgets/auth_gate.dart';

class KelimatikApp extends StatelessWidget {
  const KelimatikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelimatik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SoftPageTransitionsBuilder(),
            TargetPlatform.iOS: SoftPageTransitionsBuilder(),
            TargetPlatform.macOS: SoftPageTransitionsBuilder(),
            TargetPlatform.windows: SoftPageTransitionsBuilder(),
            TargetPlatform.linux: SoftPageTransitionsBuilder(),
            TargetPlatform.fuchsia: SoftPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthGate(),
    );
  }
}
