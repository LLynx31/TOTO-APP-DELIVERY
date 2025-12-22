import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Carte affichant les informations du livreur
class DelivererInfoCard extends StatelessWidget {
  final String? delivererName;
  final String? delivererPhone;
  final String? delivererPhoto;
  final double? rating;
  final String? vehicleInfo;

  const DelivererInfoCard({
    super.key,
    this.delivererName,
    this.delivererPhone,
    this.delivererPhoto,
    this.rating,
    this.vehicleInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          // Photo du livreur
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: delivererPhoto != null
                ? NetworkImage(delivererPhoto!)
                : null,
            child: delivererPhoto == null
                ? const Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.primary,
                  )
                : null,
          ),
          const SizedBox(width: AppSizes.spacingMd),
          // Infos livreur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      delivererName ?? 'Livreur',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: AppSizes.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingSm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (vehicleInfo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.two_wheeler,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicleInfo!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Bouton d'appel
          if (delivererPhone != null)
            IconButton(
              onPressed: () => _callDeliverer(delivererPhone!),
              icon: Container(
                padding: const EdgeInsets.all(AppSizes.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.phone,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Appeler le livreur
  Future<void> _callDeliverer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
