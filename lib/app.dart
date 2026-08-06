import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/widgets/auth_gate.dart';

class KelimatikApp extends StatelessWidget {
  const KelimatikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelimatik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
