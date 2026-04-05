import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PrivacySelector extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const PrivacySelector({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = selectedValue.trim().toLowerCase();

    return Row(
      children: [
        Expanded(
          child: _privacyCard(
            context: context,
            label: 'Public',
            icon: Icons.public,
            selected: normalizedSelected == 'public',
            onTap: () => onChanged('public'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _privacyCard(
            context: context,
            label: 'Private',
            icon: Icons.lock,
            selected: normalizedSelected == 'private',
            onTap: () => onChanged('private'),
          ),
        ),
      ],
    );
  }

  Widget _privacyCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.iconPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}