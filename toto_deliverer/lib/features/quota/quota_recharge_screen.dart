import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/models/quota_model.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/quota_pack_card.dart';

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
  QuotaPackType? _selectedPack;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.mobileMoney;
  bool _isProcessing = false;

  void _handlePurchase() async {
    if (_selectedPack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un pack'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // TODO: Implement payment logic
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isProcessing = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.textWhite,
              size: 32,
            ),
          ),
          title: const Text('Recharge réussie !'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Votre quota a été rechargé avec succès',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Column(
                  children: [
                    Text(
                      '+${_selectedPack!.deliveries} livraisons',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nouveau quota: ${widget.currentQuota + _selectedPack!.deliveries}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            CustomButton(
              text: AppStrings.ok,
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to dashboard
              },
            ),
          ],
        ),
      );
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
