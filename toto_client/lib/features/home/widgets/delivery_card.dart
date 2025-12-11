import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final VoidCallback? onTap;

  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID, status and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Delivery ID
              Text(
                '#${delivery.id.length > 8 ? delivery.id.substring(0, 8).toUpperCase() : delivery.id.toUpperCase().padLeft(8, '0')}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              // Status badge and date
              Row(
                children: [
                  StatusBadge(status: delivery.status),
                  const SizedBox(width: AppSizes.spacingSm),
                  Text(
                    _formatDate(delivery.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // From Address
          _buildAddressRow(
            context,
            icon: Icons.location_on_outlined,
            label: '${AppStrings.from}:',
            address: delivery.pickupAddress.address,
          ),

          const SizedBox(height: AppSizes.spacingSm),

          // To Address
          _buildAddressRow(
            context,
            icon: Icons.flag_outlined,
            label: '${AppStrings.to}:',
            address: delivery.deliveryAddress.address,
          ),

          const SizedBox(height: AppSizes.spacingMd),

          const Divider(),

          const SizedBox(height: AppSizes.spacingSm),

          // Footer with price and mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Delivery Mode
              Row(
                children: [
                  Icon(
                    delivery.mode == DeliveryMode.express
                        ? Icons.bolt
                        : Icons.schedule,
                    size: AppSizes.iconSizeSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.spacingXs),
                  Text(
                    delivery.mode.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),

              // Price
              Text(
                '${delivery.price.toStringAsFixed(0)} ${AppStrings.currency}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),

          // Footer with rating and delivery time (only for delivered status)
          if (delivery.status == DeliveryStatus.delivered) ...[
            const SizedBox(height: AppSizes.spacingMd),
            const Divider(),
            const SizedBox(height: AppSizes.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: AppSizes.iconSizeSm,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSizes.spacingXs),
                    Text(
                      delivery.rating != null
                          ? '${delivery.rating}/5'
                          : 'Non noté',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                // Delivery time
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: AppSizes.iconSizeSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacingXs),
                    Text(
                      _calculateDeliveryTime(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: icon == Icons.location_on_outlined
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            icon,
            size: AppSizes.iconSizeSm,
            color: icon == Icons.location_on_outlined
                ? AppColors.primary
                : AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    }
  }

  String _calculateDeliveryTime() {
    if (delivery.deliveredAt == null) {
      return 'N/A';
    }

    final duration = delivery.deliveredAt!.difference(delivery.createdAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}
