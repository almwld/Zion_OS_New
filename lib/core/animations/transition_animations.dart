import 'package:flutter/material.dart';

class TransitionAnimations {
  /// انتقال Fade (تلاشي)
  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// انتقال Slide (انزلاق)
  static Route<T> slideTransition<T>(Widget page, {Direction direction = Direction.left}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case Direction.left:
            begin = const Offset(-1, 0);
            break;
          case Direction.right:
            begin = const Offset(1, 0);
            break;
          case Direction.up:
            begin = const Offset(0, -1);
            break;
          case Direction.down:
            begin = const Offset(0, 1);
            break;
        }
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// انتقال Scale (تكبير)
  static Route<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  /// انتقال Rotate (دوران)
  static Route<T> rotateTransition<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  /// انتقال Scale + Fade (تكبير + تلاشي)
  static Route<T> scaleFadeTransition<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// انتقال Slide + Fade (انزلاق + تلاشي)
  static Route<T> slideFadeTransition<T>(Widget page, {Direction direction = Direction.left}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case Direction.left:
            begin = const Offset(-0.3, 0);
            break;
          case Direction.right:
            begin = const Offset(0.3, 0);
            break;
          default:
            begin = const Offset(-0.3, 0);
        }
        const end = Offset.zero;
        return SlideTransition(
          position: Tween(begin: begin, end: end).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// انتقال Zoom (تكبير من نقطة)
  static Route<T> zoomTransition<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(0, 0);
        var end = Offset.zero;
        var curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}

enum Direction { left, right, up, down }
