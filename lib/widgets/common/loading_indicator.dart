import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;
  final bool isOverlay;

  const LoadingIndicator({
    Key? key,
    this.size = 40.0,
    this.color,
    this.message,
    this.isOverlay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicator = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).colorScheme.primary,
            ),
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: 16,
              color: isOverlay ? Colors.white : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (isOverlay) {
      return Container(
        color: Colors.black54,
        child: Center(child: indicator),
      );
    }

    return Center(child: indicator);
  }

  /// Creates a full-screen loading overlay
  static Widget fullScreen({
    String? message,
    Color? color,
    bool dismissible = false,
  }) {
    return Stack(
      children: [
        ModalBarrier(
          dismissible: dismissible,
          color: Colors.black54,
        ),
        LoadingIndicator(
          message: message,
          color: color ?? Colors.white,
          isOverlay: true,
        ),
      ],
    );
  }

  /// Shows a loading dialog
  static Future<void> showLoadingDialog(
      BuildContext context, {
        String? message,
        bool dismissible = false,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(message ?? 'Loading...'),
            ),
          ],
        ),
      ),
    );
  }
}