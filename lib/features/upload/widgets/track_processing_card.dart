import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrackProcessingCard extends StatelessWidget {
  final double progress;
  final String statusText;
  final String percentageText;

  const TrackProcessingCard({
    super.key,
    required this.progress,
    required this.statusText,
    required this.percentageText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                ),
                const Spacer(),
                Text(
                  percentageText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryLight,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}