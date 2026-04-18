import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/auth/screens/captcha_challenge_screen.dart';
import 'package:cross/features/auth/widgets/auth_text_field.dart';
import 'package:cross/providers/auth_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isCaptchaChecked = false;
  String? captchaToken;
  String? captchaValidationMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (captchaToken == null || captchaToken!.isEmpty) {
      setState(() {
        captchaValidationMessage = 'Please complete CAPTCHA before creating an account.';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final isSuccess = await authProvider.register(
      username: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      captchaToken: captchaToken!,
    );

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.successMessage ??
                'Registration successful. Please check your email to verify.',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacementNamed(context, RouteNames.login);
      return;
    }

    final backendError = authProvider.errorMessage ?? 'Registration failed.';
    final isCaptchaError = backendError.toLowerCase().contains('captcha');
    if (isCaptchaError) {
      setState(() {
        isCaptchaChecked = false;
        captchaToken = null;
        captchaValidationMessage = 'CAPTCHA expired or invalid. Please complete it again.';
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(backendError),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCaptchaChanged(bool? value) async {
    if (value == null || value == false) {
      setState(() {
        isCaptchaChecked = false;
        captchaToken = null;
        captchaValidationMessage = null;
      });
      return;
    }

    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const CaptchaChallengeScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      setState(() {
        isCaptchaChecked = false;
        captchaToken = null;
        captchaValidationMessage = 'CAPTCHA is required to continue.';
      });
      return;
    }

    setState(() {
      isCaptchaChecked = true;
      captchaToken = token;
      captchaValidationMessage = null;
    });
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: _goToLogin,
        ),
        title: Text(
          'Create Account',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              // Profile Photo Placeholder
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceElevated,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 40),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Form Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthTextField(
                        key: const Key('register_username_field'),
                        label: 'Username',
                        hintText: 'Pick a unique name',
                        prefixIcon: Icons.person_outline_rounded,
                        controller: nameController,
                        validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        key: const Key('register_email_field'),
                        label: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icons.email_outlined,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        key: const Key('register_password_field'),
                        label: 'Password',
                        hintText: 'At least 8 characters',
                        prefixIcon: Icons.lock_outline,
                        controller: passwordController,
                        obscureText: isPasswordHidden,
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.iconSecondary, size: 20),
                          onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
                        ),
                        validator: (value) => value!.length < 8 ? 'Password too short' : null,
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        key: const Key('register_confirm_password_field'),
                        label: 'Confirm Password',
                        hintText: 'Repeat your password',
                        prefixIcon: Icons.replay_rounded,
                        controller: confirmPasswordController,
                        obscureText: isConfirmPasswordHidden,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPasswordHidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.iconSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => isConfirmPasswordHidden = !isConfirmPasswordHidden,
                          ),
                        ),
                        validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          color: AppColors.surfaceElevated,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isCaptchaChecked,
                              onChanged: isLoading ? null : _onCaptchaChanged,
                              activeColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                            ),
                            Expanded(
                              child: Text(
                                'I am not a robot',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (captchaValidationMessage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            captchaValidationMessage!,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),

                      // Gradient Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                          boxShadow: const [BoxShadow(color: AppColors.glow, blurRadius: 18, spreadRadius: 1)],
                        ),
                        child: ElevatedButton(
                          key: const Key('register_create_account_button'),
                          onPressed: isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: _goToLogin,
                    child: Text('Log In', style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}