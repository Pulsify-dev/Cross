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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(waveform.length, (index) {
          final barHeight = waveform[index] * height;
          final isPast = (index / waveform.length) <= progress;
          
          return Container(
            width: 2,
            height: barHeight,
            decoration: BoxDecoration(
              color: isPast ? progressColor : color,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }
}
