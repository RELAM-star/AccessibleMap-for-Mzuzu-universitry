import 'package:flutter/material.dart';
import 'package:accessmap_mzuni/screens/splash_screen.dart';
import 'package:accessmap_mzuni/theme/app_theme.dart';

void main() {
  runApp(AccessMapApp());
}

class AccessMapApp extends StatelessWidget {
  const AccessMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AccessMap Mzuni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
    );
  }
}