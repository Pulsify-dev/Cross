import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScrollingWaveformWidget extends StatelessWidget {
  final List<double> waveform;
  final double progress;
  final double height;
  final Color color;
  final Color progressColor;
  final Color playheadColor;
  final ValueChanged<double>? onSeek;
  final double barWidth;
  final double barGap;

  const ScrollingWaveformWidget({
    super.key,
    required this.waveform,
    this.progress = 0.0,
    this.height = 60,
    this.color = Colors.white24,
    this.progressColor = Colors.white,
    this.playheadColor = Colors.red,
    this.onSeek,
    this.barWidth = 3.0,
    this.barGap = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        return GestureDetector(
          onTapDown: (details) =>
              _handleSeek(details.localPosition.dx, viewportWidth),
          onHorizontalDragUpdate: (details) =>
              _handleSeek(details.localPosition.dx, viewportWidth),
          child: ClipRect(
            child: SizedBox(
              height: height,
              width: viewportWidth,
              child: CustomPaint(
                painter: _ScrollingWaveformPainter(
                  waveform: waveform,
                  progress: progress,
                  color: color,
                  progressColor: progressColor,
                  playheadColor: playheadColor,
                  viewportWidth: viewportWidth,
                  barWidth: barWidth,
                  barGap: barGap,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSeek(double localX, double viewportWidth) {
    if (onSeek == null || waveform.isEmpty) return;

    final centerX = viewportWidth / 2;
    final barStep = barWidth + barGap;
    final totalWaveformWidth = waveform.length * barStep;

    final tapProgress = progress + (localX - centerX) / totalWaveformWidth;
    onSeek!(tapProgress.clamp(0.0, 1.0));
  }
}

class _ScrollingWaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;
  final Color color;
  final Color progressColor;
  final Color playheadColor;
  final double viewportWidth;
  final double barWidth;
  final double barGap;

  _ScrollingWaveformPainter({
    required this.waveform,
    required this.progress,
    required this.color,
    required this.progressColor,
    required this.playheadColor,
    required this.viewportWidth,
    required this.barWidth,
    required this.barGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final barStep = barWidth + barGap;
    final totalWaveformWidth = waveform.length * barStep;
    final centerX = viewportWidth / 2;

    final offsetX = centerX - (progress * totalWaveformWidth);

    final firstVisible = math.max(0, ((0 - offsetX) / barStep).floor() - 1);
    final lastVisible = math.min(
      waveform.length - 1,
      ((viewportWidth - offsetX) / barStep).ceil() + 1,
    );

    final paint = Paint()
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final progressBarIndex = (progress * waveform.length).floor();

    for (int i = firstVisible; i <= lastVisible; i++) {
      final x = offsetX + i * barStep + barStep / 2;
      if (x < -barWidth || x > viewportWidth + barWidth) continue;

      final amplitude = waveform[i].clamp(0.0, 1.0);
      final barHeight = math.max(amplitude * size.height, 2.0);

      final yTop = (size.height - barHeight) / 2;
      final yBottom = yTop + barHeight;

      paint.color = i <= progressBarIndex ? progressColor : color;

      canvas.drawLine(Offset(x, yTop), Offset(x, yBottom), paint);
    }
    final playheadPaint = Paint()
      ..color = playheadColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = playheadColor.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScrollingWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveform != waveform ||
        oldDelegate.viewportWidth != viewportWidth;
  }
}
