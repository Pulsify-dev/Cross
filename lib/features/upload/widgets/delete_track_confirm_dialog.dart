import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DeleteTrackConfirmDialog extends StatelessWidget {
  const DeleteTrackConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Track'),
      content: const Text(
        'Are you sure you want to delete this track? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}