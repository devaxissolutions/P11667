import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_state.dart';
import '../utils/validators.dart';

class SignupForm extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToLogin;

  const SignupForm({super.key, required this.onSwitchToLogin});

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _nameError = Validators.validateName(_nameController.text);
      _emailError = Validators.validateEmail(_emailController.text);
      _passwordError = Validators.validatePassword(_passwordController.text);
    });

    if (_nameError == null && _emailError == null && _passwordError == null) {
      ref
          .read(signupControllerProvider.notifier)
          .signup(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupAsync = ref.watch(signupControllerProvider);

    // Switch to login tab on successful signup
    ref.listen(authProvider, (previous, next) {
      if (next.value is AuthAuthenticated) {
        widget.onSwitchToLogin();
      }
    });

    final isLoading = signupAsync.isLoading;
    final errorMessage = signupAsync.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),

        // Name Field
        _buildLabel('Full Name'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _nameController,
          hint: 'John Doe',
          icon: Icons.person_outline_rounded,
          isError: _nameError != null,
        ),
        if (_nameError != null) _buildError(_nameError!),

        const SizedBox(height: 24),

        // Email Field
        _buildLabel('Email Address'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          hint: 'name@example.com',
          icon: Icons.email_outlined,
          isError: _emailError != null,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_emailError != null) _buildError(_emailError!),

        const SizedBox(height: 24),

        // Password Field
        _buildLabel('Password'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscurePassword,
          isError: _passwordError != null,
          toggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        if (_passwordError != null) _buildError(_passwordError!),

        const SizedBox(height: 32),

        // Error message from API
        if (errorMessage != null)
          _buildBannerError(errorMessage),

        // Signup Button
        GestureDetector(
          onTap: isLoading ? null : _validateAndSubmit,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR SIGN UP WITH',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
          ],
        ),

        const SizedBox(height: 32),

        // Google Sign Up Button
        GestureDetector(
          onTap: isLoading ? null : () => ref.read(signupControllerProvider.notifier).signInWithGoogle(),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                  height: 24,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Sign up with Google',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
        
        // Already have an account?
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
            GestureDetector(
              onTap: widget.onSwitchToLogin,
              child: Text(
                'Sign In',
                style: GoogleFonts.inter(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isError,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey[600],
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        error,
        style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }

  Widget _buildBannerError(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
