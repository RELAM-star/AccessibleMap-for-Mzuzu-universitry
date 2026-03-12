import 'package:flutter/material.dart';
import 'package:accessmap_mzuni/screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AccessMapApp());
}

class AccessMapApp extends StatelessWidget {
  const AccessMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AccessMap Mzuni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginScreen(),
    );
  }
}