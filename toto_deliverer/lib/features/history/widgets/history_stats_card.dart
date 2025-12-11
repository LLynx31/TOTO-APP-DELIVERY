import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Card affichant les statistiques de l'historique
class HistoryStatsCard extends StatelessWidget {
  final double totalEarned;
  final int totalDeliveries;
  final double successRate;

  const HistoryStatsCard({
    super.key,
    required this.totalEarned,
    required this.totalDeliveries,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppSizes.paddingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    icon: Icons.payments_outlined,
                    label: 'Total gagné',
                    value: '${totalEarned.toStringAsFixed(0)} F',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    icon: Icons.local_shipping_outlined,
                    label: 'Livraisons',
                    value: '$totalDeliveries',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    icon: Icons.check_circle_outline,
                    label: 'Taux réussite',
                    value: '${successRate.toStringAsFixed(0)}%',
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
