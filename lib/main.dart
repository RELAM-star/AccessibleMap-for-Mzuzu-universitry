import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:accessmap_mzuni/firebase_options.dart';
import 'package:accessmap_mzuni/screens/splash_screen.dart';
import 'package:accessmap_mzuni/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const SplashScreen(),
    );
  }
}