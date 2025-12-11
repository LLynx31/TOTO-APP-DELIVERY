import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/delivery_model.dart';

class ETADistanceWidget extends StatelessWidget {
  final DeliveryStatus status;
  final double distanceKm;

  const ETADistanceWidget({
    super.key,
    required this.status,
    required this.distanceKm,
  });

  String _calculateETA() {
    switch (status) {
      case DeliveryStatus.pending:
      case DeliveryStatus.accepted:
        return '15-20 ${AppStrings.minutes}';
      case DeliveryStatus.pickupInProgress:
        return '8-10 ${AppStrings.minutes}';
      case DeliveryStatus.pickedUp:
        return '12-15 ${AppStrings.minutes}';
      case DeliveryStatus.deliveryInProgress:
        return '5-8 ${AppStrings.minutes}';
      case DeliveryStatus.delivered:
        return 'Livré';
      default:
        return 'Calculé...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // ETA Section
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizes.spacingXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.estimatedArrival,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                      ),
                      Text(
                        _calculateETA(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 32,
            color: AppColors.primary.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSm),
          ),

          // Distance Section
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizes.spacingXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.distance,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                      ),
                      Text(
                        status == DeliveryStatus.delivered
                            ? '0 ${AppStrings.kilometers}'
                            : '${distanceKm.toStringAsFixed(1)} ${AppStrings.kilometers}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
