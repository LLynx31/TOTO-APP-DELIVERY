import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/delivery_model.dart';

class DeliveryModeBadge extends StatelessWidget {
  final DeliveryMode mode;
  final bool isCompact;

  const DeliveryModeBadge({
    super.key,
    required this.mode,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    final isExpress = mode == DeliveryMode.express;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSizes.paddingSm : AppSizes.paddingMd,
        vertical: isCompact ? 4 : AppSizes.paddingSm,
      ),
      decoration: BoxDecoration(
        color: (isExpress ? AppColors.express : AppColors.standard)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: isExpress ? AppColors.express : AppColors.standard,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpress ? Icons.bolt : Icons.schedule,
            size: isCompact ? 14 : 16,
            color: isExpress ? AppColors.express : AppColors.standard,
          ),
          const SizedBox(width: AppSizes.spacingXs),
          Text(
            mode.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isExpress ? AppColors.express : AppColors.standard,
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 10 : 12,
                ),
          ),
        ],
      ),
    );
  }
}
