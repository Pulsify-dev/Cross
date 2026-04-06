import 'package:flutter/material.dart';

class UploadTrackConfirmDialog extends StatelessWidget {
  const UploadTrackConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Track'),
      content: const Text(
        'Are you sure you want to upload this track?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Upload'),
        ),
      ],
    );
  }
}