import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  final String? label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final int maxLines;

  const AuthTextField({
    super.key,
    this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          maxLines: obscureText ? 1 : maxLines,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primaryLight,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: AppColors.iconSecondary,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.inputBackground,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.error, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}
