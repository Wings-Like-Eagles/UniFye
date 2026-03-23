import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unifye/core/router/app_router.dart';

/// These will be set by the entrypoint (e.g. main_dev.dart)
String baseUrl = '';
String environment = '';

void main({String? baseUrlParam, String? environmentParam}) {
  final defaultBaseUrl = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:5219'
      : 'http://localhost:5219';

  // Allow defaults if not passed
  baseUrl = baseUrlParam ?? defaultBaseUrl;
  environment = environmentParam ?? 'development';

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorSchemeSeed: const Color(0xFFFF4B6E),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Flutter Dev Environment',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      ),
      home: const AppRouter(), // ✅ Now uses router that checks auth state
    );
  }
}
