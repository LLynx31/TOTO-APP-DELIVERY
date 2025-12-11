import 'package:flutter/material.dart';

/// A reusable gradient background widget for the entire app.
/// Creates a solid white background.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF), // Blanc pur
      ),
      child: child,
    );
  }
}
