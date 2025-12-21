import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../controllers/forgot_password_controller.dart';
import '../utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _emailError = Validators.validateEmail(_emailController.text);
    });

    if (_emailError == null) {
      ref.read(forgotPasswordProvider.notifier).setEmail(_emailController.text);
      ref.read(forgotPasswordProvider.notifier).sendResetLink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    // Navigate to success screen when link is sent
    ref.listen(forgotPasswordProvider, (previous, next) {
      if (next.isSuccess) {
        context.go('/auth/reset-link-sent');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.03),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  
                  // Modern Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Illustration/Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 64,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Header Text
                  Text(
                    'Forgot Password?',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Don\'t worry! It happens. Please enter the email address associated with your account.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Email Input Field
                  Text(
                    'Email Address',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _emailError != null || state.error != null
                            ? Colors.redAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: Colors.white),
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'name@example.com',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  if (_emailError != null || state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _emailError ?? state.error!,
                        style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Submit Button
                  GestureDetector(
                    onTap: state.isLoading ? null : _validateAndSubmit,
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
                        child: state.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Send Link',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  // Still having trouble?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remembered your password? ',
                        style: GoogleFonts.inter(color: Colors.grey[500]),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Login',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
