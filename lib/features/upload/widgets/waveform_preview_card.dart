import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WaveformPreviewCard extends StatelessWidget {
  const WaveformPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bars = [10, 20, 30, 22, 34, 18, 28, 12, 8, 16, 26, 18, 10, 6];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Waveform Preview',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Auto-generated after processing',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars
                    .map(
                      (h) => Container(
                        width: 10,
                        height: h.toDouble(),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}