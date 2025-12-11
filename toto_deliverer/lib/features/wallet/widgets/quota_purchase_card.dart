import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/transaction_model.dart';

class QuotaPurchaseCard extends StatelessWidget {
  final TransactionModel transaction;

  const QuotaPurchaseCard({
    super.key,
    required this.transaction,
  });

  String _getPackName() {
    // Extract pack info from description
    final amount = transaction.amount;
    if (amount >= 30000) return 'Pack Premium';
    if (amount >= 15000) return 'Pack Pro';
    if (amount >= 5000) return 'Pack Standard';
    return 'Pack Basique';
  }

  int _getQuotaCount() {
    // Estimate quota based on amount (simplified)
    final amount = transaction.amount;
    if (amount >= 30000) return 50;
    if (amount >= 15000) return 20;
    if (amount >= 5000) return 10;
    return 5;
  }

  IconData _getPackIcon() {
    final amount = transaction.amount;
    if (amount >= 30000) return Icons.workspace_premium;
    if (amount >= 15000) return Icons.verified;
    if (amount >= 5000) return Icons.card_giftcard;
    return Icons.local_offer;
  }

  Color _getPackColor() {
    final amount = transaction.amount;
    if (amount >= 30000) return const Color(0xFFFFD700); // Gold
    if (amount >= 15000) return AppColors.primary;
    if (amount >= 5000) return AppColors.info;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    final packColor = _getPackColor();

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: transaction.status == TransactionStatus.pending
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and pack name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSm),
                decoration: BoxDecoration(
                  color: packColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  _getPackIcon(),
                  color: packColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPackName(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${_getQuotaCount()} livraisons',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${NumberFormat('#,##0', 'fr_FR').format(transaction.amount)} FCFA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                  ),
                  if (transaction.status == TransactionStatus.pending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Text(
                        'En attente',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Separator
          const Divider(height: 1),

          const SizedBox(height: AppSizes.spacingSm),

          // Footer with date, time, and transaction ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.spacingXs),
                  Text(
                    dateFormat.format(transaction.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: AppSizes.spacingMd),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.spacingXs),
                  Text(
                    timeFormat.format(transaction.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              Text(
                '#${transaction.id.substring(0, 6)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
