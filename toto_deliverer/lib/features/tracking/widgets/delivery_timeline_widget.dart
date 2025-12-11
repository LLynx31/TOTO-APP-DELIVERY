import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/delivery_model.dart';

class DeliveryTimelineWidget extends StatelessWidget {
  final DeliveryStatus currentStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const DeliveryTimelineWidget({
    super.key,
    required this.currentStatus,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.deliveryTimeline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _buildTimelineStep(
            context: context,
            icon: Icons.check_circle,
            title: AppStrings.orderCreated,
            time: _formatTime(acceptedAt ?? createdAt),
            isCompleted: true,
            isCurrent: currentStatus == DeliveryStatus.accepted,
            isLast: false,
          ),
          _buildTimelineStep(
            context: context,
            icon: Icons.directions,
            title: AppStrings.routeToPickup,
            time: currentStatus.index >= DeliveryStatus.pickupInProgress.index
                ? _formatTime(acceptedAt ?? createdAt)
                : AppStrings.pending,
            isCompleted: currentStatus.index > DeliveryStatus.pickupInProgress.index,
            isCurrent: currentStatus == DeliveryStatus.pickupInProgress,
            isLast: false,
            subtitle: currentStatus == DeliveryStatus.pickupInProgress
                ? 'Scanner le QR pour confirmer la réception'
                : null,
          ),
          _buildTimelineStep(
            context: context,
            icon: Icons.qr_code_scanner,
            title: AppStrings.arrivedAtPickup,
            time: currentStatus.index >= DeliveryStatus.pickedUp.index
                ? _formatTime(pickedUpAt ?? DateTime.now())
                : AppStrings.pending,
            isCompleted: currentStatus.index > DeliveryStatus.pickedUp.index,
            isCurrent: false,
            isLast: false,
            subtitle: currentStatus == DeliveryStatus.pickupInProgress
                ? 'QR code requis'
                : null,
          ),
          _buildTimelineStep(
            context: context,
            icon: Icons.inventory,
            title: AppStrings.packageCollected,
            time: pickedUpAt != null
                ? _formatTime(pickedUpAt!)
                : AppStrings.pending,
            isCompleted: currentStatus.index > DeliveryStatus.pickedUp.index,
            isCurrent: currentStatus == DeliveryStatus.pickedUp,
            isLast: false,
          ),
          _buildTimelineStep(
            context: context,
            icon: Icons.local_shipping,
            title: AppStrings.routeToDelivery,
            time: currentStatus.index >= DeliveryStatus.deliveryInProgress.index
                ? _formatTime(pickedUpAt ?? DateTime.now())
                : AppStrings.pending,
            isCompleted: currentStatus.index > DeliveryStatus.deliveryInProgress.index,
            isCurrent: currentStatus == DeliveryStatus.deliveryInProgress,
            isLast: false,
            subtitle: currentStatus == DeliveryStatus.deliveryInProgress
                ? 'Scanner le QR pour confirmer la livraison'
                : null,
          ),
          _buildTimelineStep(
            context: context,
            icon: Icons.qr_code_scanner,
            title: 'Arrivé au point B',
            time: currentStatus.index >= DeliveryStatus.delivered.index
                ? _formatTime(deliveredAt ?? DateTime.now())
                : AppStrings.pending,
            isCompleted: currentStatus == DeliveryStatus.delivered,
            isCurrent: false,
            isLast: false,
            subtitle: currentStatus == DeliveryStatus.deliveryInProgress
                ? 'QR code ou code manuel requis'
                : null,
          ),
          _buildTimelineStep(
            context: context,
            icon: Icons.done_all,
            title: AppStrings.deliveryComplete,
            time: deliveredAt != null
                ? _formatTime(deliveredAt!)
                : AppStrings.pending,
            isCompleted: currentStatus == DeliveryStatus.delivered,
            isCurrent: currentStatus == DeliveryStatus.delivered,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String time,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator column
        Column(
          children: [
            // Circle with icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.surfaceGrey,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: AppColors.primary, width: 3)
                    : null,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isCompleted || isCurrent
                    ? AppColors.textWhite
                    : AppColors.textTertiary,
              ),
            ),
            // Connector line
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isCompleted ? AppColors.primary : AppColors.border,
              ),
          ],
        ),

        const SizedBox(width: AppSizes.spacingMd),

        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isCurrent || isCompleted
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isCurrent
                                ? AppColors.primary
                                : isCompleted
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Text(
                        AppStrings.inProgress,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingXs),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 12,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isLast) const SizedBox(height: AppSizes.spacingSm),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}
