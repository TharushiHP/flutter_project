import 'package:flutter/material.dart';

/// Animated progress indicator with smooth animations
class AnimatedProgressIndicator extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final Duration duration;

  const AnimatedProgressIndicator({
    super.key,
    required this.value,
    required this.color,
    this.height = 4.0,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: color.withValues(alpha: 0.3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: duration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: color,
          ),
        ),
      ),
    );
  }
}
