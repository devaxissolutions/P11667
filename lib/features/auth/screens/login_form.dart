import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/colors.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_state.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_divider.dart';
import '../widgets/google_sign_in_button.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _emailError = Validators.validateEmail(_emailController.text);
      _passwordError = Validators.validatePassword(_passwordController.text);
    });

    if (_emailError == null && _passwordError == null) {
      ref
          .read(loginControllerProvider.notifier)
          .login(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginAsync = ref.watch(loginControllerProvider);

    // Navigate to home on successful login
    ref.listen(authProvider, (previous, next) {
      if (next.value is AuthAuthenticated) {
        context.go('/home');
      }
    });

    final isLoading = loginAsync.isLoading;
    final errorMessage = loginAsync.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),

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
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage,
              style: AppTypography.body2.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Login button
        PrimaryButton(
          text: 'Log In',
          onPressed: isLoading ? null : _validateAndSubmit,
          isLoading: isLoading,
        ),

        const SizedBox(height: 24),

        // Divider
        const AuthDivider(),

        const SizedBox(height: 24),

        // Google sign-in button
        GoogleSignInButton(
          text: 'Sign in with Google',
          onPressed: () {
            ref.read(loginControllerProvider.notifier).signInWithGoogle();
          },
          isLoading: loginAsync.isLoading,
        ),

        const SizedBox(height: 24),

        // Forgot password link
        Center(
          child: TextButton(
            onPressed: () {
              context.push('/auth/forgot-password');
            },
            child: Text(
              'Forgot Password?',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
