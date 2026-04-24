import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> waveform;
  final double progress;
  final double height;
  final Color color;
  final Color progressColor;

  const WaveformWidget({
    super.key,
    required this.waveform,
    this.progress = 0.0,
    this.height = 60,
    this.color = Colors.white24,
    this.progressColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: WaveformPainter(
          waveform: waveform,
          progress: progress,
          color: color,
          progressColor: progressColor,
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;
  final Color color;
  final Color progressColor;

  WaveformPainter({
    required this.waveform,
    required this.progress,
    required this.color,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / waveform.length;

    for (int i = 0; i < waveform.length; i++) {
      final x = i * spacing + spacing / 2;
      final barHeight = waveform[i] * size.height;
      // Guard against zero or negative height
      final validBarHeight = barHeight > 0 ? barHeight : 2.0; 
      final isPast = (i / waveform.length) <= progress;

      paint.color = isPast ? progressColor : color;

      final yTop = (size.height - validBarHeight) / 2;
      final yBottom = yTop + validBarHeight;

      canvas.drawLine(Offset(x, yTop), Offset(x, yBottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveform != waveform;
  }
}
