import 'package:flutter/material.dart';

class AnimationUtils {
  /// Creates a fade transition animation
  static Widget fadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Creates a slide transition animation
  static Widget slideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset? beginOffset,
    Curve curve = Curves.easeInOut,
  }) {
    final tween = Tween(
      begin: beginOffset ?? Offset(0.0, 0.3),
      end: Offset.zero,
    );

    return SlideTransition(
      position: animation.drive(tween.chain(
        CurveTween(curve: curve),
      )),
      child: child,
    );
  }

  /// Creates a combined fade and slide transition
  static Widget fadeSlideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset? beginOffset,
    Curve curve = Curves.easeInOut,
  }) {
    return FadeTransition(
      opacity: animation,
      child: slideTransition(
        animation: animation,
        beginOffset: beginOffset,
        curve: curve,
        child: child,
      ),
    );
  }

  /// Creates a scale transition animation
  static Widget scaleTransition({
    required Animation<double> animation,
    required Widget child,
    Alignment alignment = Alignment.center,
    double beginScale = 0.8,
    Curve curve = Curves.easeInOut,
  }) {
    final tween = Tween(
      begin: beginScale,
      end: 1.0,
    );

    return ScaleTransition(
      scale: animation.drive(tween.chain(
        CurveTween(curve: curve),
      )),
      alignment: alignment,
      child: child,
    );
  }

  /// Creates a staggered animation for a list of widgets
  static List<Widget> staggeredList({
    required List<Widget> children,
    required Animation<double> animation,
    Duration? staggerDuration,
    Curve curve = Curves.easeInOut,
    bool fadeIn = true,
    bool slideIn = true,
    Offset? slideOffset,
  }) {
    final staggers = List.generate(
      children.length,
          (index) {
        final interval = Interval(
          index / children.length,
          (index + 1) / children.length,
          curve: curve,
        );

        final staggeredAnimation = CurvedAnimation(
          parent: animation,
          curve: interval,
        );

        Widget child = children[index];

        if (slideIn && fadeIn) {
          return fadeSlideTransition(
            animation: staggeredAnimation,
            beginOffset: slideOffset,
            child: child,
          );
        } else if (fadeIn) {
          return fadeTransition(
            animation: staggeredAnimation,
            child: child,
          );
        } else if (slideIn) {
          return slideTransition(
            animation: staggeredAnimation,
            beginOffset: slideOffset,
            child: child,
          );
        }

        return child;
      },
    );

    return staggers;
  }
}