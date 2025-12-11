import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/delivery_utils.dart';
import '../../../shared/models/delivery_model.dart';
import '../../../shared/widgets/widgets.dart';

class AvailableCourseCard extends StatelessWidget {
  final DeliveryModel delivery;
  final VoidCallback onTap;
  final bool isNew; // Course postée il y a moins de 5 minutes

  const AvailableCourseCard({
    super.key,
    required this.delivery,
    required this.onTap,
    this.isNew = false,
  });

  // Calcul de la distance approximative entre 2 points (formule de Haversine)
  double _calculateDistance() {
    const double earthRadius = 6371; // km

    final lat1 = delivery.pickupAddress.latitude;
    final lon1 = delivery.pickupAddress.longitude;
    final lat2 = delivery.deliveryAddress.latitude;
    final lon2 = delivery.deliveryAddress.longitude;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // Estimation du temps de trajet (vitesse moyenne 30 km/h en ville)
  int _estimatedTimeMinutes() {
    final distance = _calculateDistance();
    final hours = distance / 30; // 30 km/h vitesse moyenne
    return (hours * 60).round();
  }

  // Calcul du revenu par km
  double _revenuePerKm() {
    final distance = _calculateDistance();
    if (distance == 0) return 0;
    return delivery.price / distance;
  }

  String get _deliveryModeText {
    switch (delivery.mode) {
      case DeliveryMode.standard:
        return AppStrings.standard;
      case DeliveryMode.express:
        return AppStrings.express;
    }
  }

  Color get _deliveryModeColor {
    switch (delivery.mode) {
      case DeliveryMode.standard:
        return AppColors.info;
      case DeliveryMode.express:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DeliveryUtils.formatDeliveryIdWithPrefix(delivery.id),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // Badge "Nouvelle course"
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        border: Border.all(
                          color: AppColors.success,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_new,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nouvelle',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (isNew) const SizedBox(width: AppSizes.spacingSm),
                  // Badge mode de livraison
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _deliveryModeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color: _deliveryModeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _deliveryModeText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _deliveryModeColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Pickup Location
              _buildLocationRow(
                context: context,
                icon: Icons.radio_button_checked,
                iconColor: AppColors.primary,
                label: AppStrings.from,
                address: delivery.pickupAddress.address,
              ),

              const SizedBox(height: AppSizes.spacingSm),

              // Destination Location
              _buildLocationRow(
                context: context,
                icon: Icons.location_on,
                iconColor: AppColors.error,
                label: AppStrings.to,
                address: delivery.deliveryAddress.address,
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Package Details + Distance + Time
              Wrap(
                spacing: AppSizes.spacingSm,
                runSpacing: AppSizes.spacingSm,
                children: [
                  _buildInfoChip(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    label: delivery.package.size.displayName,
                  ),
                  _buildInfoChip(
                    context: context,
                    icon: Icons.scale_outlined,
                    label: '${delivery.package.weight}kg',
                  ),
                  _buildInfoChip(
                    context: context,
                    icon: Icons.social_distance,
                    label: '${_calculateDistance().toStringAsFixed(1)} km',
                    color: AppColors.info,
                  ),
                  _buildInfoChip(
                    context: context,
                    icon: Icons.access_time,
                    label: '~${_estimatedTimeMinutes()} min',
                    color: AppColors.warning,
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingSm),

              // Revenu par km
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_revenuePerKm().toStringAsFixed(0)} FCFA/km',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.spacingMd),

              const Divider(height: 1),

              const SizedBox(height: AppSizes.spacingMd),

              // Price and Action
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.proposedPrice,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${delivery.price.toStringAsFixed(0)} FCFA',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLg,
                        vertical: AppSizes.paddingMd,
                      ),
                    ),
                    child: Text(AppStrings.seeDetails),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm,
        vertical: AppSizes.paddingSm,
      ),
      decoration: BoxDecoration(
        color: color != null
            ? color.withValues(alpha: 0.1)
            : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
