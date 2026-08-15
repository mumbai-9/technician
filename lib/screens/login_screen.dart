import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B3D8C),
              Color(0xFF2E6CDE),
              Color(0xFFF6F9FF),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _buildLogo(),
                      const SizedBox(height: 18),
                      _buildWelcomeText(),
                      const SizedBox(height: 30),
                      _buildLoginForm(),
                      const SizedBox(height: 20),
                      _buildRememberAndForgot(),
                      const SizedBox(height: 28),
                      _buildLoginButton(),
                      const SizedBox(height: 18),
                      _buildFooterNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C4EA2), Color(0xFF3A7DF0)],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A7DF0).withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.shield_rounded,
          size: 56,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          'Welcome Back!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF123A6B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7E5FF)),
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2E6CDE)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7E5FF)),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Password',
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF2E6CDE),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF2E6CDE),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _rememberMe
                      ? const Color(0xFF2E6CDE)
                      : const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD7E5FF)),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2E6CDE),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D4DA1), Color(0xFF2E6CDE)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6CDE).withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : const Text(
                    'LOGIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Text(
      'Secure technician access portal',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.5,
        color: Colors.grey[600],
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _handleLogin() async {
    // Validate input
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Email and Password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Call API
      final result = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Save user data
        debugPrint('💾 Saving user data: ${result['data']}');
        await AuthService.saveUserData(result['data']);
        debugPrint('✅ User data saved successfully');

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${result['data']['name']}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        if (!mounted) return;
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
