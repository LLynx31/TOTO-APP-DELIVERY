import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Icône de succès animée avec checkmark
class AnimatedSuccessIcon extends StatefulWidget {
  final double size;
  final Duration duration;

  const AnimatedSuccessIcon({
    super.key,
    this.size = 120.0,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedSuccessIcon> createState() => _AnimatedSuccessIconState();
}

class _AnimatedSuccessIconState extends State<AnimatedSuccessIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _checkmarkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    );

    // Démarrer l'animation après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _checkmarkAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _checkmarkAnimation.value,
                child: Icon(
                  Icons.check,
                  size: widget.size * 0.6,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
