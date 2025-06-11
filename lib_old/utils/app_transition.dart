import 'package:flutter/material.dart';

class AppTransitions {
  AppTransitions._();

  /// Slide transition
  ///
  /// Parameters:
  ///
  /// - `BuildContext context`
  /// - `Animation<double> animation`
  /// - `Animation<double> secondaryAnimation`
  /// - `Widget child`
  static Widget slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.ease;

    final tween = Tween(begin: begin, end: end);
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

    return SlideTransition(
      position: tween.animate(curvedAnimation),
      child: child,
    );
  }

  /// Create slide route
  ///
  /// Parameters:
  ///
  /// - `Widget page`
  static PageRouteBuilder createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: slideTransition,
    );
  }
}
