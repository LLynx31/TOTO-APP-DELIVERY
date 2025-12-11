import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? AppSizes.elevationMd,
      color: color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ??
            BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Padding(
        padding: padding ??
            const EdgeInsets.all(AppSizes.paddingMd),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius as BorderRadius? ??
            BorderRadius.circular(AppSizes.radiusXl),
        child: card,
      );
    }

    return card;
  }
}
