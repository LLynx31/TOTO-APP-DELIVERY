import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/quota_model.dart';
import '../../../shared/widgets/widgets.dart';

/// Écran de reçu après un paiement réussi
class PaymentReceiptScreen extends StatelessWidget {
  final QuotaPackType pack;
  final PaymentMethod paymentMethod;
  final int previousQuota;
  final int newQuota;
  final String transactionId;

  const PaymentReceiptScreen({
    super.key,
    required this.pack,
    required this.paymentMethod,
    required this.previousQuota,
    required this.newQuota,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reçu de paiement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          children: [
            // Success icon
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 56,
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Success message
            Text(
              'Paiement réussi !',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingSm),

            Text(
              'Votre quota a été rechargé avec succès',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Receipt details
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails de la transaction',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Transaction details
                    _buildDetailRow(
                      context,
                      'ID Transaction',
                      transactionId,
                    ),

                    _buildDivider(),

                    _buildDetailRow(
                      context,
                      'Pack acheté',
                      pack.name,
                    ),

                    _buildDivider(),

                    _buildDetailRow(
                      context,
                      'Livraisons ajoutées',
                      '+${pack.deliveries}',
                      valueColor: AppColors.success,
                    ),

                    _buildDivider(),

                    _buildDetailRow(
                      context,
                      'Montant payé',
                      '${pack.price.toStringAsFixed(0)} FCFA',
                      valueColor: AppColors.primary,
                      valueBold: true,
                    ),

                    _buildDivider(),

                    _buildDetailRow(
                      context,
                      'Méthode de paiement',
                      paymentMethod.displayName,
                    ),

                    _buildDivider(),

                    _buildDetailRow(
                      context,
                      'Date et heure',
                      _formatDateTime(DateTime.now()),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Quota summary
            CustomCard(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      'Nouveau quota',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    Text(
                      '$newQuota',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    Text(
                      'livraisons disponibles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                        vertical: AppSizes.paddingSm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ancien quota: $previousQuota',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(width: AppSizes.spacingSm),
                          const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: AppSizes.spacingSm),
                          Text(
                            'Nouveau: $newQuota',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Actions
            CustomButton(
              text: 'Retour au tableau de bord',
              onPressed: () {
                // Retourner au dashboard en fermant toutes les pages de recharge
                // Pop jusqu'au dashboard (ou root)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),

            const SizedBox(height: AppSizes.spacingMd),

            TextButton.icon(
              onPressed: () {
                // TODO: Implement share/download receipt
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Partager le reçu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
