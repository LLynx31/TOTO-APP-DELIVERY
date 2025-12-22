import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Widget pour sélectionner une note en étoiles (1-5)
class StarRatingInput extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
    this.activeColor = AppColors.warning,
    this.inactiveColor = AppColors.border,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput>
    with SingleTickerProviderStateMixin {
  late int _currentRating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int rating) {
    setState(() {
      _currentRating = rating;
    });

    // Animation de bounce
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isActive = starNumber <= _currentRating;

        return GestureDetector(
          onTap: () => _handleTap(starNumber),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: starNumber == _currentRating ? _scaleAnimation.value : 1.0,
                  child: Icon(
                    isActive ? Icons.star : Icons.star_border,
                    size: widget.size,
                    color: isActive ? widget.activeColor : widget.inactiveColor,
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
