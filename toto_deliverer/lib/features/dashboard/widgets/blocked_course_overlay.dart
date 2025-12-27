import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Overlay semi-transparent affiché sur les courses bloquées
/// quand le livreur a déjà une course en cours ou est hors ligne
class BlockedCourseOverlay extends StatelessWidget {
  final String? reason;

  const BlockedCourseOverlay({
    super.key,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = reason?.contains('ligne') ?? false;
    final title = reason ?? 'Terminez votre course actuelle';
    final subtitle = isOffline
        ? 'Activez votre disponibilité pour voir les détails'
        : 'Vous pourrez accepter cette course une fois votre livraison terminée';

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSm),
                decoration: BoxDecoration(
                  color: (isOffline ? AppColors.error : AppColors.warning)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOffline ? Icons.wifi_off : Icons.block,
                  color: isOffline ? AppColors.error : AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSizes.spacingMd),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSizes.spacingSm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
