import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/providers/auth_provider.dart';
import 'package:cross/features/auth/widgets/auth_text_field.dart';
import 'package:cross/features/auth/widgets/social_auth_button.dart';
import 'package:cross/routes/route_names.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final isSuccess = await authProvider.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      Navigator.pushReplacementNamed(context, RouteNames.mainScreen);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Login failed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToSignUp() {
      Navigator.pushNamed(context, RouteNames.register);
  }

  void _goToForgotPassword() {
    Navigator.pushNamed(context, RouteNames.forgotPassword);
  }

  void _handleGoogleLogin() {
    // TODO: implement Google sign in
  }

  void _handleAppleLogin() {
    // TODO: implement Apple sign in
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevated,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primaryLight,
                  size: 32,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Pulsify',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Listen to your favorite tracks anywhere',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Welcome Back',
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      AuthTextField(
                        label: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icons.email_outlined,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }

                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: _goToForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      AuthTextField(
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        controller: passwordController,
                        obscureText: isPasswordHidden,
                        textInputAction: TextInputAction.done,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isPasswordHidden = !isPasswordHidden;
                            });
                          },
                          icon: Icon(
                            isPasswordHidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.iconSecondary,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.glow,
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Log In',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.divider.withValues(alpha: 0.8),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.divider.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          SocialAuthButton(
                            text: 'Google',
                            icon: const Icon(
                              Icons.g_mobiledata_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _handleGoogleLogin,
                          ),
                          const SizedBox(width: 12),
                          SocialAuthButton(
                            text: 'Apple',
                            icon: const Icon(
                              Icons.apple,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _handleAppleLogin,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _goToSignUp,
                    child: Text(
                      'Sign Up',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
