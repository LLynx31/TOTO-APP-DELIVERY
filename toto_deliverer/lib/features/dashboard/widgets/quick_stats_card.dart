import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Card compacte affichant les statistiques rapides du jour
class QuickStatsCard extends StatelessWidget {
  final double earningsToday;
  final int deliveriesToday;
  final int remainingQuota;

  const QuickStatsCard({
    super.key,
    required this.earningsToday,
    required this.deliveriesToday,
    required this.remainingQuota,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Gains du jour
          Expanded(
            child: _buildStatItem(
              context: context,
              icon: Icons.payments_outlined,
              label: "Aujourd'hui",
              value: '${earningsToday.toStringAsFixed(0)} F',
              color: AppColors.success,
            ),
          ),

          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),

          // Livraisons du jour
          Expanded(
            child: _buildStatItem(
              context: context,
              icon: Icons.local_shipping_outlined,
              label: 'Livraisons',
              value: '$deliveriesToday',
              color: AppColors.primary,
            ),
          ),

          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),

          // Quota restant
          Expanded(
            child: _buildStatItem(
              context: context,
              icon: Icons.inventory_2_outlined,
              label: 'Quota',
              value: '$remainingQuota',
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: AppSizes.spacingXs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
