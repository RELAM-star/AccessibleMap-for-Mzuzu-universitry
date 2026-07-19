// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:accessmap_mzuni/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  final AuthService _authService = AuthService();

  Future<void> _send() async {
    setState(() => _loading = true);
    final error = await _authService.resetPassword(_emailController.text.trim());
    setState(() { _loading = false; _sent = error == null; });
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: const Color(0xFFE74C3C)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(children: [
                  Icon(Icons.arrow_back, color: Color(0xFF1A7A6E), size: 20),
                  SizedBox(width: 6),
                  Text('Back to login', style: TextStyle(color: Color(0xFF1A7A6E), fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 40),
              Container(width: 70, height: 70, decoration: BoxDecoration(color: const Color(0xFF1A7A6E).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_reset, color: Color(0xFF1A7A6E), size: 36)),
              const SizedBox(height: 20),
              const Text('Forgot Password?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A3C38))),
              const SizedBox(height: 8),
              Text('Enter your email and we will send you a reset link.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 32),
              if (!_sent) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Color(0xFF7A9E9B)),
                    prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF7A9E9B), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF1A7A6E), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _send,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135C52), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1A7A6E).withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1A7A6E).withOpacity(0.3))),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: Color(0xFF1A7A6E), size: 28),
                    SizedBox(width: 12),
                    Expanded(child: Text('Reset link sent! Check your email inbox.', style: TextStyle(color: Color(0xFF1A3C38), fontWeight: FontWeight.w600))),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}