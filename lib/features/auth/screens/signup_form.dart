import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/colors.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_state.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_divider.dart';
import '../widgets/google_sign_in_button.dart';

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
          .read(authProvider.notifier)
          .signup(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final authState = authAsync.value;

    // Switch to login tab on successful signup
    ref.listen(authProvider, (previous, next) {
      if (next.value is AuthAuthenticated) {
        widget.onSwitchToLogin();
      }
    });

    AuthMethod authLoadingAction = AuthMethod.none;
    if (authState is AuthLoading) {
      authLoadingAction = authState.action;
    }
    final isLoading = authLoadingAction == AuthMethod.signup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),

        // Name field
        AuthTextField(
          label: 'Name',
          hint: 'Enter your name',
          controller: _nameController,
          errorText: _nameError,
          onChanged: (_) {
            if (_nameError != null) {
              setState(() => _nameError = null);
            }
          },
        ),

        const SizedBox(height: 24),

        // Email field
        AuthTextField(
          label: 'Email',
          hint: 'Enter your email',
          controller: _emailController,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
        ),

        const SizedBox(height: 24),

        // Password field
        AuthTextField(
          label: 'Password',
          hint: 'Enter your password',
          isPassword: true,
          controller: _passwordController,
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
        ),

        const SizedBox(height: 32),

        // Error message
        if (authState is AuthError) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              authState.message,
              style: AppTypography.body2.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Signup button
        PrimaryButton(
          text: 'Sign Up',
          onPressed: isLoading ? null : _validateAndSubmit,
          isLoading: isLoading,
        ),

        const SizedBox(height: 24),

        // Divider
        const AuthDivider(),

        const SizedBox(height: 24),

        // Google sign-in button
        GoogleSignInButton(
          text: 'Sign up with Google',
          onPressed: () {
            ref.read(authProvider.notifier).signInWithGoogle();
          },
          isLoading: authLoadingAction == AuthMethod.google,
        ),

        const SizedBox(height: 24),

        // Login link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: widget.onSwitchToLogin,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Log In',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
