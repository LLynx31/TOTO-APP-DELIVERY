import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class QRDisplayScreen extends StatelessWidget {
  final String deliveryId;
  final String qrType;

  const QRDisplayScreen({
    super.key,
    required this.deliveryId,
    required this.qrType,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = qrType == 'pickup';
    final title = isPickup ? 'QR Code Ramassage' : 'QR Code Livraison';
    final description = isPickup
        ? 'Présentez ce code au livreur pour confirmer le ramassage du colis'
        : 'Présentez ce code au livreur pour confirmer la réception du colis';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSizes.spacingLg),

            // Icône de type
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isPickup
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPickup ? Icons.upload : Icons.download,
                  size: 40,
                  color: isPickup ? AppColors.primary : AppColors.success,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: '$deliveryId:$qrType',
                  version: QrVersions.auto,
                  size: 280.0,
                  gapless: true,
                  errorStateBuilder: (context, error) {
                    return const Center(
                      child: Text(
                        'Erreur de génération du QR code',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // ID de livraison
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    'ID de livraison',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  Text(
                    deliveryId,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Instructions
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: isPickup
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isPickup ? AppColors.primary : AppColors.success,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color:
                            isPickup ? AppColors.primary : AppColors.success,
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        'Instructions',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingSm),
                  _buildInstruction(isPickup
                      ? '1. Montrez ce code QR au livreur'
                      : '1. Vérifiez le colis avant de scanner'),
                  _buildInstruction(isPickup
                      ? '2. Le livreur scannera le code pour confirmer le ramassage'
                      : '2. Montrez ce code au livreur après vérification'),
                  _buildInstruction(isPickup
                      ? '3. Vous recevrez une notification de confirmation'
                      : '3. Le livreur scannera le code pour confirmer la livraison'),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implémenter le partage du QR code
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à venir'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.paddingMd,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implémenter la sauvegarde du QR code
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à venir'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Sauvegarder'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.paddingMd,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.paddingMd,
        bottom: AppSizes.spacingXs,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
