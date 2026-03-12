// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back to login
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(children: [
                  Icon(Icons.arrow_back, color: Color(0xFF1A7A6E), size: 20),
                  SizedBox(width: 6),
                  Text('Back to login', style: TextStyle(color: Color(0xFF1A7A6E), fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 28),
              const Text('Sign Up', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1A3C38))),
              const SizedBox(height: 28),

              _field(_nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 14),
              _field(_emailController, 'Email', Icons.mail_outline, type: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _passwordField(_passwordController, 'Password', _obscure, () => setState(() => _obscure = !_obscure)),
              const SizedBox(height: 14),
              _passwordField(_confirmController, 'Confirm Password', _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 14),
              _field(_phoneController, 'Phone', Icons.phone_outlined, type: TextInputType.phone),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135C52),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7A9E9B)),
        prefixIcon: Icon(icon, color: const Color(0xFF7A9E9B), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF1A7A6E), width: 1.5)),
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String hint, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7A9E9B)),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7A9E9B), size: 20),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF7A9E9B), size: 20), onPressed: toggle),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF1A7A6E), width: 1.5)),
      ),
    );
  }
}