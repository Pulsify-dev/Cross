import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WaveformPreviewCard extends StatelessWidget {
  const WaveformPreviewCard({
    super.key,
    this.peaks,
    this.isLoading = false,
    this.errorText,
  });

  final List<double>? peaks;
  final bool isLoading;
  final String? errorText;

  bool get _hasError => errorText != null && errorText!.trim().isNotEmpty;

  bool get _hasPeaks => (peaks ?? const <double>[]).isNotEmpty;

  List<double> _normalizedBars() {
    final values = peaks ?? const <double>[];
    if (values.isEmpty) return const <double>[];

    if (values.length <= 14) return values;

    final step = values.length / 14;
    final compressed = <double>[];
    for (var i = 0; i < 14; i++) {
      final idx = (i * step).floor().clamp(0, values.length - 1);
      compressed.add(values[idx]);
    }
    return compressed;
  }

  @override
  Widget build(BuildContext context) {
    final bars = _normalizedBars();
    const loadingBars = <double>[
      0.24,
      0.34,
      0.46,
      0.38,
      0.28,
      0.36,
      0.26,
      0.2,
      0.31,
      0.42,
      0.33,
      0.24,
      0.18,
      0.28,
    ];

    final subtitle = isLoading
        ? 'Generating waveform...'
        : _hasError
            ? 'Could not load waveform'
            : _hasPeaks
                ? 'Auto-generated after processing'
                : 'Waveform will appear after processing';

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
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: loadingBars
                          .map(
                            (value) => Container(
                              width: 10,
                              height: (value.clamp(0.05, 1.0) * 40.0) + 8.0,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : _hasError
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorText!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        )
                      : !_hasPeaks
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Waveform will appear after processing',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: bars
                                  .map(
                                    (value) => Container(
                                      width: 10,
                                      height: (value.clamp(0.05, 1.0) * 40.0) + 8.0,
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