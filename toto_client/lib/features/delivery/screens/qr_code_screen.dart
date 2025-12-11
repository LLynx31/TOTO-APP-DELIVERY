import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/widgets.dart';

class QRCodeScreen extends StatelessWidget {
  final String deliveryId;
  final String qrCode;

  const QRCodeScreen({
    super.key,
    required this.deliveryId,
    required this.qrCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de livraison'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSizes.spacingXl),

            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 48,
                color: AppColors.success,
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Title
            Text(
              'Colis en attente de livraison',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // QR Code Card
            CustomCard(
              child: Column(
                children: [
                  Text(
                    'Montrez ce QR au livreur pour valider la réception.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.spacingLg),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLg),
                    decoration: BoxDecoration(
                      color: AppColors.textWhite,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: AppColors.textWhite,
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Delivery ID
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Delivery ID Tertiage Eliynen',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSizes.spacingXs),
                        Text(
                          '136ly 0908/51 space.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Validity Info
                  Text(
                    '${AppStrings.validUntil} 04:59',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),

                  const SizedBox(height: AppSizes.spacingLg),

                  // Refresh Button
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Refresh QR code
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.refreshQR),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // Delivery Point Image Section
            Text(
              'Point de livraison (Adresse de destination)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Map placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: AppColors.textTertiary,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // WhatsApp Contact Button
            CustomButton(
              text: 'Contacter livreur via WhatsApp',
              onPressed: () {
                // TODO: Open WhatsApp
              },
              icon: const Icon(
                Icons.chat,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
