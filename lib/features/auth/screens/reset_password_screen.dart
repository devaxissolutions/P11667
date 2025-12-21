import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/reset_password_controller.dart';
import '../utils/validators.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? oobCode;

  const ResetPasswordScreen({super.key, this.oobCode});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _newPasswordError = Validators.validatePassword(
        _newPasswordController.text,
      );
      _confirmPasswordError = Validators.validatePasswordMatch(
        _newPasswordController.text,
        _confirmPasswordController.text,
      );
    });

    if (_newPasswordError == null && _confirmPasswordError == null) {
      ref
          .read(resetPasswordProvider.notifier)
          .setNewPassword(_newPasswordController.text);
      ref
          .read(resetPasswordProvider.notifier)
          .setConfirmPassword(_confirmPasswordController.text);
      ref
          .read(resetPasswordProvider.notifier)
          .resetPassword(widget.oobCode ?? 'mock-oobCode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordProvider);

    // Navigate to success screen when password is reset
    ref.listen(resetPasswordProvider, (previous, next) {
      if (next.isSuccess) {
        context.go('/auth/reset-success');
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

                  // Header Icon
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
                        Icons.shield_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 64,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Header Text
                  Text(
                    'Reset Password',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set a strong, secure password to protect your account.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // New Password field
                  _buildLabel('New Password'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _newPasswordController,
                    hint: 'Enter your new password',
                    obscureText: _obscureNew,
                    icon: Icons.lock_outline_rounded,
                    isError: _newPasswordError != null,
                    toggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  if (_newPasswordError != null)
                    _buildError(_newPasswordError!),

                  const SizedBox(height: 24),

                  // Confirm Password field
                  _buildLabel('Confirm Password'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Re-enter your new password',
                    obscureText: _obscureConfirm,
                    icon: Icons.lock_outline_rounded,
                    isError: _confirmPasswordError != null || state.error != null,
                    toggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  if (_confirmPasswordError != null || state.error != null)
                    _buildError(_confirmPasswordError ?? state.error!),

                  const SizedBox(height: 48),

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
                                'Update Password',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required IconData icon,
    required bool isError,
    required VoidCallback toggleVisibility,
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
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.grey[600],
            ),
            onPressed: toggleVisibility,
          ),
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
}
