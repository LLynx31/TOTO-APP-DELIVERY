import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/widgets.dart';

class StatusQuotaCard extends StatefulWidget {
  final bool isOnline;
  final int remainingDeliveries;
  final int totalQuota; // Total quota pour la barre de progression
  final bool hasActiveQuota; // Indique si le livreur a un pack actif
  final VoidCallback onToggleOnline;
  final VoidCallback onRechargeQuota;

  const StatusQuotaCard({
    super.key,
    required this.isOnline,
    required this.remainingDeliveries,
    this.totalQuota = 20, // Default max quota
    this.hasActiveQuota = true,
    required this.onToggleOnline,
    required this.onRechargeQuota,
  });

  @override
  State<StatusQuotaCard> createState() => _StatusQuotaCardState();
}

class _StatusQuotaCardState extends State<StatusQuotaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(StatusQuotaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animation when online status changes
    if (oldWidget.isOnline != widget.isOnline && widget.isOnline) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isOnline) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _quotaColor {
    if (widget.remainingDeliveries == 0) return AppColors.quotaEmpty;
    if (widget.remainingDeliveries <= 2) return AppColors.quotaLow;
    return AppColors.quota;
  }

  /// Affichage quand le livreur a un pack actif avec des quotas
  Widget _buildActiveQuotaDisplay(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            color: _quotaColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: _quotaColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _quotaColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.remainingDeliveries}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.quotaRemaining,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.remainingDeliveries} ${AppStrings.deliveries}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _quotaColor,
                          ),
                    ),
                  ],
                ),
              ),
              if (widget.remainingDeliveries <= 2 && widget.remainingDeliveries > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    'Faible',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // Recharge Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onRechargeQuota,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Recharger mon quota'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingMd,
              ),
            ),
          ),
        ),

        if (widget.remainingDeliveries == 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spacingMd),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: AppSizes.spacingSm),
                Expanded(
                  child: Text(
                    AppStrings.rechargeQuota,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Affichage quand le livreur n'a pas encore acheté de pack
  Widget _buildNoPackDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icon illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Title
          Text(
            'Aucun pack actif',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),

          const SizedBox(height: AppSizes.spacingSm),

          // Description
          Text(
            'Achetez un pack de courses pour commencer à effectuer des livraisons et gagner de l\'argent.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingLg),

          // CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onRechargeQuota,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Acheter un pack'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.paddingMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.spacingSm),

          // Info text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'À partir de 8 000 FCFA',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              AppStrings.myStatusAndQuota,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Online Status Toggle with animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isOnline ? _pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color: widget.isOnline
                      ? AppColors.online.withValues(alpha: 0.1)
                      : AppColors.offline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.isOnline ? AppColors.online : AppColors.offline,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isOnline ? Icons.check : Icons.close,
                        color: AppColors.textWhite,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isOnline ? AppStrings.online : AppStrings.offline,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: widget.isOnline ? AppColors.online : AppColors.offline,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isOnline
                                ? 'Vous recevez des courses'
                                : 'Vous ne recevez pas de courses',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.isOnline,
                      onChanged: widget.remainingDeliveries > 0
                          ? (_) => widget.onToggleOnline()
                          : null,
                      activeThumbColor: AppColors.online,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Quota Display - UI différente selon si pack actif ou non
            if (widget.hasActiveQuota)
              _buildActiveQuotaDisplay(context)
            else
              _buildNoPackDisplay(context),
          ],
        ),
      ),
    );
  }
}
