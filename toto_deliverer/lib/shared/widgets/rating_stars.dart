import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class RatingStars extends StatefulWidget {
  final int rating;
  final Function(int)? onRatingChanged;
  final double size;
  final bool readOnly;

  const RatingStars({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = AppSizes.iconSizeMd,
    this.readOnly = false,
  });

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() {
                    _currentRating = index + 1;
                  });
                  widget.onRatingChanged?.call(_currentRating);
                },
          child: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            color: AppColors.warning,
            size: widget.size,
          ),
        );
      }),
    );
  }
}
