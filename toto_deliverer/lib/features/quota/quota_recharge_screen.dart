import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/quota_service.dart';
import '../../shared/models/quota_model.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/quota_pack_card.dart';
import 'widgets/payment_confirmation_dialog.dart';
import 'widgets/payment_processing_dialog.dart';
import 'widgets/payment_receipt_screen.dart';

class QuotaRechargeScreen extends StatefulWidget {
  final int currentQuota;

  const QuotaRechargeScreen({
    super.key,
    required this.currentQuota,
  });

  @override
  State<QuotaRechargeScreen> createState() => _QuotaRechargeScreenState();
}

class _QuotaRechargeScreenState extends State<QuotaRechargeScreen> {
  final _quotaService = QuotaService();
  QuotaPackType? _selectedPack;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.mobileMoney;
  bool _isProcessing = false;

  /// Gère le processus de paiement complet
  void _handlePurchase() async {
    // 1. Validation du formulaire
    if (_selectedPack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un pack'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // 2. Afficher le dialog de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PaymentConfirmationDialog(
        pack: _selectedPack!,
        paymentMethod: _selectedPaymentMethod,
        onConfirm: () {},
      ),
    );

    if (confirmed == null || !mounted) return;

    // 3. Afficher le dialog de processing et effectuer le paiement
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentProcessingDialog(
        onProcess: () => _processPurchase(),
      ),
    );

    if (!mounted) return;

    // 4. Gérer le résultat
    if (success == true) {
      // Succès: naviguer vers l'écran de reçu
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentReceiptScreen(
            pack: _selectedPack!,
            paymentMethod: _selectedPaymentMethod,
            previousQuota: widget.currentQuota,
            newQuota: widget.currentQuota + _selectedPack!.deliveries,
            transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
    } else {
      // Échec: afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le paiement a échoué. Veuillez réessayer.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Traite l'achat de quota via l'API
  Future<void> _processPurchase() async {
    try {
      // Mapper le pack type vers un package ID
      final packageId = _getPackageId(_selectedPack!);

      // Appel API (simulé pour l'instant car nous n'avons pas l'ID du deliverer)
      // TODO: Récupérer le vrai deliverer ID depuis l'auth state
      final delivererId = 'deliverer-id-placeholder';

      await _quotaService.purchaseQuota(
        delivererId: delivererId,
        packageId: packageId,
        paymentMethod: _selectedPaymentMethod.name,
      );

      // Succès
    } catch (e) {
      // Propager l'erreur pour qu'elle soit gérée par le dialog
      rethrow;
    }
  }

  /// Mappe un QuotaPackType vers un package ID pour l'API
  String _getPackageId(QuotaPackType pack) {
    switch (pack) {
      case QuotaPackType.pack5:
        return 'BASIC'; // 5 livraisons
      case QuotaPackType.pack10:
        return 'STANDARD'; // 10 livraisons
      case QuotaPackType.pack20:
        return 'PREMIUM'; // 20 livraisons
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.rechargeYourQuota),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Quota Display
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.currentQuota > 0
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.currentQuota}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.currentQuota > 0
                                    ? AppColors.primary
                                    : AppColors.error,
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
                            AppStrings.currentQuota,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.currentQuota} ${AppStrings.deliveries}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

            // Choose Pack Header
            Text(
              AppStrings.chooseAPack,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Pack Options
            ...QuotaPackType.values.map((pack) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                  child: QuotaPackCard(
                    packType: pack,
                    isSelected: _selectedPack == pack,
                    onTap: () => setState(() => _selectedPack = pack),
                  ),
                )),

            const SizedBox(height: AppSizes.spacingXl),

            // Payment Method
            Text(
              'Méthode de paiement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            ...PaymentMethod.values.map((method) => CustomCard(
                  child: RadioListTile<PaymentMethod>(
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPaymentMethod = value);
                      }
                    },
                    title: Text(method.displayName),
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSm,
                    ),
                  ),
                )),

            const SizedBox(height: AppSizes.spacingXl),

            // Info Message
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.spacingSm),
                  Expanded(
                    child: Text(
                      AppStrings.quotaWillBeConverted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Purchase Button
            CustomButton(
              text: _selectedPack != null
                  ? 'Payer ${_selectedPack!.price.toStringAsFixed(0)} FCFA'
                  : AppStrings.payViaMobileMoney,
              onPressed: _handlePurchase,
              isLoading: _isProcessing,
            ),

            const SizedBox(height: AppSizes.spacingXl),
          ],
        ),
      ),
    );
  }
}
