import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_system/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PosmiApp()));
}

class PosmiApp extends StatelessWidget {
  const PosmiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PosmiFood',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(child: Text('PosmiFood — Fase 0 lista')),
      ),
    );
  }
}
