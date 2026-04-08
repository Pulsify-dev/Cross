import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AudioPickerCard extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPick;

  const AudioPickerCard({
    super.key,
    required this.fileName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primaryLight,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fileName ?? 'Select Audio File',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Supports MP3, WAV, FLAC, AAC',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onPick,
                child: const Text('Choose File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}