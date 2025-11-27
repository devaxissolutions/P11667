import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/reset_password_controller.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Reset Password',
                style: AppTypography.title2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // New password field
              AuthTextField(
                label: 'New Password',
                hint: 'Enter your new password',
                isPassword: true,
                controller: _newPasswordController,
                errorText: _newPasswordError,
                onChanged: (_) {
                  if (_newPasswordError != null) {
                    setState(() => _newPasswordError = null);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Confirm password field
              AuthTextField(
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                isPassword: true,
                controller: _confirmPasswordController,
                errorText: _confirmPasswordError ?? state.error,
                onChanged: (_) {
                  if (_confirmPasswordError != null) {
                    setState(() => _confirmPasswordError = null);
                  }
                },
              ),

              const Spacer(),

              // Set new password button
              PrimaryButton(
                text: 'Set New Password',
                onPressed: state.isLoading ? null : _validateAndSubmit,
                isLoading: state.isLoading,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
