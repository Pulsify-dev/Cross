import 'package:cross/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FollowActionButton extends StatelessWidget {
  const FollowActionButton({
    super.key,
    required this.label,
    required this.active,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final bool active;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? AppColors.primary : AppColors.surfaceElevated,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: active ? AppColors.primary : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
    );
  }
}
