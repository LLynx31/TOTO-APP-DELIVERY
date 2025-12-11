import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Card affichant les statistiques avancées du livreur
class AdvancedStatsCard extends StatelessWidget {
  final double earningsThisMonth;
  final List<double> earningsLast7Days;
  final double completionRate;
  final Duration averageDeliveryTime;
  final Duration totalTimeOnline;

  const AdvancedStatsCard({
    super.key,
    required this.earningsThisMonth,
    required this.earningsLast7Days,
    required this.completionRate,
    required this.averageDeliveryTime,
    required this.totalTimeOnline,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Statistiques du mois',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingLg),

            // Gains du mois avec mini graphique
            _buildEarningsSection(context),
            const SizedBox(height: AppSizes.spacingLg),

            // Grid de statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    icon: Icons.check_circle_outline,
                    label: 'Taux de complétion',
                    value: '${completionRate.toStringAsFixed(0)}%',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    icon: Icons.timer_outlined,
                    label: 'Temps moyen',
                    value: _formatDuration(averageDeliveryTime),
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingMd),

            // Temps total en ligne
            _buildStatItem(
              context: context,
              icon: Icons.schedule_outlined,
              label: 'Temps en ligne ce mois',
              value: _formatDuration(totalTimeOnline),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gains du mois',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${earningsThisMonth.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+12%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingMd),

        // Mini graphique
        _buildMiniChart(context),
      ],
    );
  }

  Widget _buildMiniChart(BuildContext context) {
    if (earningsLast7Days.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = earningsLast7Days.reduce((a, b) => a > b ? a : b);
    final minValue = earningsLast7Days.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(earningsLast7Days.length, (index) {
          final value = earningsLast7Days[index];
          final normalizedHeight = range > 0 ? (value - minValue) / range : 0.5;
          final barHeight = 20 + (normalizedHeight * 40); // Min 20, max 60

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
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
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
