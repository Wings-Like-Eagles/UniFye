import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pages/login-page.dart';

/// These will be set by the entrypoint (e.g. main_dev.dart)
String baseUrl = '';
String environment = '';

void main({String? baseUrlParam, String? environmentParam}) {
  // Allow defaults if not passed
  baseUrl = baseUrlParam ?? 'http://localhost:3000';
  environment = environmentParam ?? 'development';

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dev Environment',
      home: LoginPage(),
    );
  }
}
