import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ArtworkPickerCard extends StatelessWidget {
  final String title;
  final VoidCallback onPick;
  final bool showChangeAction;

  const ArtworkPickerCard({
    super.key,
    required this.title,
    required this.onPick,
    this.showChangeAction = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.surfaceElevated,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.iconPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Square image recommended',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (showChangeAction) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onPick,
                      child: const Text('Choose Artwork'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}