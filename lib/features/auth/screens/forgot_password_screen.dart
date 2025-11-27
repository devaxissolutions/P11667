import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/forgot_password_controller.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';

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
                'Forgot Password',
                style: AppTypography.title2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Enter your email to receive a password reset link.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Email field
              AuthTextField(
                label: 'Email',
                hint: 'Enter your email address',
                controller: _emailController,
                errorText: _emailError ?? state.error,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),

              const Spacer(),

              // Send reset link button
              PrimaryButton(
                text: 'Send Reset Link',
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
