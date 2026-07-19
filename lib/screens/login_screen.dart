import 'package:flutter/material.dart';
import 'package:accessmap_mzuni/screens/home_screen.dart';
import 'package:accessmap_mzuni/screens/register_screen.dart';
import 'package:accessmap_mzuni/screens/forgot_password_screen.dart';
import 'package:accessmap_mzuni/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    setState(() => _loading = true);
    final error = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    setState(() => _loading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: const Color(0xFFE74C3C)),
      );
      return;
    }
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A7A6E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * 0.38,
                      child: Stack(
                        children: [
                          Positioned(top: -30, right: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle))),
                          Positioned(top: 20, right: 30, child: Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle))),
                          Padding(
                            padding: const EdgeInsets.only(left: 36, top: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Hello!', style: TextStyle(color: Colors.white, fontSize: constraints.maxWidth < 600 ? 36 : 48, fontWeight: FontWeight.w900, height: 1.1)),
                                ),
                                const Text('Welcome to AccessMap Mzuni', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 36, bottom: 20,
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.accessibility_new, color: Colors.white, size: 44),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F4F3),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A3C38))),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: const TextStyle(color: Color(0xFF7A9E9B)),
                                prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF7A9E9B), size: 20),
                                filled: true, fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF1A7A6E), width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(color: Color(0xFF7A9E9B)),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7A9E9B), size: 20),
                                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF7A9E9B), size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
                                filled: true, fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF1A7A6E), width: 1.5)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen())),
                                child: const Text('Forgot Password', style: TextStyle(color: Color(0xFF1A7A6E), fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135C52), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(children: [
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('Or login with', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                            ]),
                            const SizedBox(height: 20),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              _socialBtn(Icons.facebook, const Color(0xFF1877F2)),
                              const SizedBox(width: 16),
                              _socialBtn(Icons.g_mobiledata, const Color(0xFFDB4437)),
                              const SizedBox(width: 16),
                              _socialBtn(Icons.apple, Colors.black),
                            ]),
                            const SizedBox(height: 24),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                                child: const Text('Sign Up', style: TextStyle(color: Color(0xFF1A7A6E), fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _socialBtn(IconData icon, Color color) {
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
