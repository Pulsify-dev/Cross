import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/auth/widgets/auth_text_field.dart';
import 'package:cross/routes/route_names.dart';

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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement registration logic
      Navigator.pushReplacementNamed(context, RouteNames.home);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
          style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              // Profile Photo Section
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
              Text('Set Profile Photo', style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              Text('Personalize your music profile', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              
              const SizedBox(height: 24),

              // Registration Form
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
                        label: 'Username',
                        hintText: 'Pick a unique name',
                        prefixIcon: Icons.person_outline_rounded,
                        controller: nameController,
                        validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
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
                        label: 'Confirm Password',
                        hintText: 'Repeat your password',
                        prefixIcon: Icons.replay_rounded,
                        controller: confirmPasswordController,
                        obscureText: isConfirmPasswordHidden,
                        validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
                      ),
                      
                      const SizedBox(height: 30),

                      // Gradient Button with Glow
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [AppColors.gradientStart, AppColors.gradientEnd],
                          ),
                          boxShadow: const [
                            BoxShadow(color: AppColors.glow, blurRadius: 18, spreadRadius: 1),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Bottom Link
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}