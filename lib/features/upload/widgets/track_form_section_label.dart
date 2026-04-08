import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrackFormSectionLabel extends StatelessWidget {
  final String text;

  const TrackFormSectionLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}