import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/root_scaffold.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: KasBicaraApp()));
}

class KasBicaraApp extends StatelessWidget {
  const KasBicaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KasBicara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const RootScaffold(),
    );
  }
}
