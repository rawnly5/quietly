import 'dart:math';

import 'package:flutter/material.dart';

class WaveformIndicator extends StatefulWidget {
  const WaveformIndicator({super.key, required this.active, required this.noiseDb});
  final bool active;
  final double noiseDb;

  @override
  State<WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (BuildContext _, __) => CustomPaint(
          painter: _WavePainter(
            t: _ctrl.value,
            active: widget.active,
            intensity: ((widget.noiseDb + 60) / 60).clamp(0.1, 1.0),
            color: Theme.of(context).colorScheme.primary,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.t, required this.active, required this.intensity, required this.color});
  final double t;
  final bool active;
  final double intensity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final int bars = 32;
    final double w = size.width / bars;
    final Paint p = Paint()..color = active ? color : Colors.grey.withOpacity(0.4);
    for (int i = 0; i < bars; i++) {
      final double phase = (i / bars * 2 * pi) + t * 2 * pi;
      final double h = active
          ? (sin(phase) * 0.5 + 0.5) * size.height * intensity
          : size.height * 0.1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(i * w + w / 2, size.height / 2), width: w * 0.6, height: max(4, h)),
          const Radius.circular(3),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}
