import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/models/delivery_model.dart';

class StatusBadge extends StatelessWidget {
  final DeliveryStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  Color get backgroundColor {
    switch (status) {
      case DeliveryStatus.pending:
      case DeliveryStatus.accepted:
        return AppColors.warning;
      case DeliveryStatus.pickupInProgress:
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.deliveryInProgress:
        return AppColors.courseInProgress;
      case DeliveryStatus.delivered:
        return AppColors.courseCompleted;
      case DeliveryStatus.cancelled:
        return AppColors.courseCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: backgroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
