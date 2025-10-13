import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class FocusProgressIndicator extends StatelessWidget {
  final double percent;
  final double radius;
  final double lineWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Widget? center;
  final bool animation;
  final Duration animationDuration;
  final String? footer;

  const FocusProgressIndicator({
    Key? key,
    required this.percent,
    this.radius = 100.0,
    this.lineWidth = 10.0,
    required this.progressColor,
    required this.backgroundColor,
    this.center,
    this.animation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: radius,
          lineWidth: lineWidth,
          percent: percent.clamp(0.0, 1.0),
          center: center,
          progressColor: progressColor,
          backgroundColor: backgroundColor,
          circularStrokeCap: CircularStrokeCap.round,
          animation: animation,
          animationDuration: animationDuration.inMilliseconds,
        ),
        if (footer != null) ...[
          SizedBox(height: 16),
          Text(
            footer!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  /// Creates a timer progress indicator
  static Widget timer({
    required Duration remaining,
    required Duration total,
    Color? progressColor,
    Color? backgroundColor,
    double radius = 100.0,
    double lineWidth = 10.0,
    bool showTimeInCenter = true,
    String? label,
    bool animation = true,
    BuildContext? context,
  }) {
    final percent = 1.0 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return FocusProgressIndicator(
      percent: percent,
      radius: radius,
      lineWidth: lineWidth,
      progressColor: progressColor ?? Colors.blue,
      backgroundColor: backgroundColor ?? Colors.blue.withOpacity(0.2),
      animation: animation,
      center: showTimeInCenter
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontSize: radius / 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (label != null) ...[
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: radius / 8,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      )
          : null,
    );
  }
}