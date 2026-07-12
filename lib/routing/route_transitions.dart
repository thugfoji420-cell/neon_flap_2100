import 'package:flutter/material.dart';

/// Smooth fade/slide page transitions used for premium-feeling navigation.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 320),
    );

/// Replaces the current route with a faded transition.
Future<T?> replaceWithFade<T>(BuildContext context, Widget page) =>
    Navigator.of(context).pushReplacement(fadeRoute<T>(page));

/// Pushes a new route with a faded transition.
Future<T?> pushWithFade<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push(fadeRoute<T>(page));
