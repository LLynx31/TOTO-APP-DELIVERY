import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/delivery.dart';

/// Carte compacte pour afficher une livraison
class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;

  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      elevation: AppSizes.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut et prix
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(),
                  Text(
                    Formatters.currency(delivery.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMd),

              // Point de départ
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.spacingSm),
                  Expanded(
                    child: Text(
                      delivery.pickupLocation.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingXs),

              // Ligne verticale
              Padding(
                padding: const EdgeInsets.only(left: 5.5),
                child: Container(
                  width: 1,
                  height: 16,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingXs),

              // Point d'arrivée
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSizes.spacingSm),
                  Expanded(
                    child: Text(
                      delivery.deliveryLocation.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Bas avec distance et date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSizes.spacingXs),
                      Text(
                        '${(delivery.distanceKm ?? 0).toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    Formatters.relativeTime(delivery.timestamps.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (delivery.status) {
      case DeliveryStatus.pending:
        backgroundColor = AppColors.statusPending.withValues(alpha: 0.1);
        textColor = AppColors.statusPending;
        label = AppStrings.pending;
        break;
      case DeliveryStatus.accepted:
        backgroundColor = AppColors.statusAccepted.withValues(alpha: 0.1);
        textColor = AppColors.statusAccepted;
        label = AppStrings.accepted;
        break;
      case DeliveryStatus.pickupInProgress:
        backgroundColor = AppColors.statusPickupInProgress.withValues(alpha: 0.1);
        textColor = AppColors.statusPickupInProgress;
        label = AppStrings.pickupInProgress;
        break;
      case DeliveryStatus.pickedUp:
        backgroundColor = AppColors.statusPickedUp.withValues(alpha: 0.1);
        textColor = AppColors.statusPickedUp;
        label = AppStrings.pickedUp;
        break;
      case DeliveryStatus.deliveryInProgress:
        backgroundColor = AppColors.statusDeliveryInProgress.withValues(alpha: 0.1);
        textColor = AppColors.statusDeliveryInProgress;
        label = AppStrings.deliveryInProgress;
        break;
      case DeliveryStatus.delivered:
        backgroundColor = AppColors.statusDelivered.withValues(alpha: 0.1);
        textColor = AppColors.statusDelivered;
        label = AppStrings.delivered;
        break;
      case DeliveryStatus.cancelled:
        backgroundColor = AppColors.statusCancelled.withValues(alpha: 0.1);
        textColor = AppColors.statusCancelled;
        label = AppStrings.cancelled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingSm,
        vertical: AppSizes.spacingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
