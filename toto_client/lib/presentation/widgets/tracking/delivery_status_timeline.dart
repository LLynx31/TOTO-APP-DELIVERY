import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/delivery.dart';

/// Widget timeline affichant les étapes de la livraison
class DeliveryStatusTimeline extends StatelessWidget {
  final DeliveryStatus currentStatus;

  const DeliveryStatusTimeline({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statut de la livraison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _buildTimelineStep(
            title: 'En attente',
            subtitle: 'Recherche d\'un livreur',
            status: DeliveryStatus.pending,
            isFirst: true,
          ),
          _buildTimelineStep(
            title: 'Livreur assigné',
            subtitle: 'En route vers le point de départ',
            status: DeliveryStatus.pickupInProgress,
          ),
          _buildTimelineStep(
            title: 'Colis récupéré',
            subtitle: 'Le livreur a le colis',
            status: DeliveryStatus.pickedUp,
          ),
          _buildTimelineStep(
            title: 'En cours de livraison',
            subtitle: 'En route vers la destination',
            status: DeliveryStatus.deliveryInProgress,
          ),
          _buildTimelineStep(
            title: 'Livré',
            subtitle: 'Colis délivré avec succès',
            status: DeliveryStatus.delivered,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required DeliveryStatus status,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isCompleted = _isStatusCompleted(status);
    final isActive = currentStatus == status;
    final color = isCompleted || isActive ? AppColors.success : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            // Top line
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: _isStatusCompleted(_getPreviousStatus(status))
                    ? AppColors.success
                    : AppColors.border,
              ),
            // Circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.success,
                    )
                  : isActive
                      ? Container(
                          margin: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        )
                      : null,
            ),
            // Bottom line
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSizes.spacingMd),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: 2,
              bottom: isLast ? 0 : AppSizes.spacingMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Vérifie si un statut est complété par rapport au statut actuel
  bool _isStatusCompleted(DeliveryStatus status) {
    final statusOrder = [
      DeliveryStatus.pending,
      DeliveryStatus.pickupInProgress,
      DeliveryStatus.pickedUp,
      DeliveryStatus.deliveryInProgress,
      DeliveryStatus.delivered,
    ];

    final currentIndex = statusOrder.indexOf(currentStatus);
    final statusIndex = statusOrder.indexOf(status);

    return statusIndex < currentIndex;
  }

  /// Retourne le statut précédent dans la timeline
  DeliveryStatus _getPreviousStatus(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pickupInProgress:
        return DeliveryStatus.pending;
      case DeliveryStatus.pickedUp:
        return DeliveryStatus.pickupInProgress;
      case DeliveryStatus.deliveryInProgress:
        return DeliveryStatus.pickedUp;
      case DeliveryStatus.delivered:
        return DeliveryStatus.deliveryInProgress;
      default:
        return DeliveryStatus.pending;
    }
  }
}
