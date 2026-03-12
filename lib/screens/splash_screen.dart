// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF135C52),
      body: Stack(
        children: [
          // Decorative circles background
          Positioned(top: -40, right: -40, child: Container(width: 180, height: 180, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
          Positioned(top: 80, right: 60, child: Container(width: 90, height: 90, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
          Positioned(bottom: -60, left: -40, child: Container(width: 220, height: 220, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
          Positioned(bottom: 100, left: 30, child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon box
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.accessible_forward_rounded,
                        size: 64,
                        color: Color(0xFF1A7A6E),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'AccessMap',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mzuzu University',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.78),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 56),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.8),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}