import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/models/quota_model.dart';
import '../../shared/widgets/widgets.dart';
import 'providers/quota_provider.dart';
import 'quota_history_screen.dart';
import 'widgets/quota_pack_card.dart';
import 'widgets/payment_confirmation_dialog.dart';
import 'widgets/payment_processing_dialog.dart';
import 'widgets/payment_receipt_screen.dart';

class QuotaRechargeScreen extends ConsumerStatefulWidget {
  final int currentQuota;

  const QuotaRechargeScreen({
    super.key,
    required this.currentQuota,
  });

  @override
  ConsumerState<QuotaRechargeScreen> createState() => _QuotaRechargeScreenState();
}

class _QuotaRechargeScreenState extends ConsumerState<QuotaRechargeScreen> {
  QuotaPackType? _selectedPack;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.orangeMoney;
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

    // 2. Afficher le dialog de confirmation et attendre la réponse
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PaymentConfirmationDialog(
        pack: _selectedPack!,
        paymentMethod: _selectedPaymentMethod,
      ),
    );

    // L'utilisateur a annulé ou fermé le dialog
    if (confirmed != true || !mounted) return;

    // 3. Afficher le dialog de processing et effectuer le paiement
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentProcessingDialog(
        onProcess: () => _processPurchase(),
      ),
    );

    if (!mounted) return;

    // 4. Gérer le résultat
    if (result == true) {
      // Succès: récupérer le nouveau quota depuis le provider
      final newQuota = ref.read(quotaProvider).activeQuota;
      final newRemainingDeliveries = newQuota?.remainingDeliveries ?? 0;

      print('✅ Payment success! New quota: $newRemainingDeliveries deliveries');

      // Naviguer vers l'écran de reçu
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentReceiptScreen(
            pack: _selectedPack!,
            paymentMethod: _selectedPaymentMethod,
            previousQuota: widget.currentQuota,
            newQuota: newRemainingDeliveries,
            transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
    } else {
      // Échec: afficher un message d'erreur détaillé
      String errorMessage = 'Le paiement a échoué. Veuillez réessayer.';

      // Si on a reçu un objet d'erreur avec plus de détails
      if (result is Map && result['error'] != null) {
        final error = result['error'].toString();
        print('💥 Payment error details: $error');

        // Analyser l'erreur pour donner un message plus clair
        if (error.contains('401') || error.contains('Unauthorized')) {
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        } else if (error.contains('403') || error.contains('Forbidden')) {
          errorMessage = 'Accès refusé. Vérifiez vos permissions.';
        } else if (error.contains('400') || error.contains('Bad Request')) {
          errorMessage = 'Données invalides. Veuillez vérifier vos informations.';
        } else if (error.contains('500') || error.contains('Server Error')) {
          errorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
        } else if (error.contains('Network') || error.contains('Connection')) {
          errorMessage = 'Problème de connexion. Vérifiez votre internet.';
        } else {
          // Inclure une partie du message d'erreur si disponible
          errorMessage = 'Erreur: ${error.length > 100 ? error.substring(0, 100) + '...' : error}';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Traite l'achat de quota via l'API (JWT-based)
  Future<void> _processPurchase() async {
    try {
      // Utiliser le provider Riverpod pour acheter le quota
      // Le backend extrait l'ID du livreur depuis le token JWT
      await ref.read(quotaProvider.notifier).purchaseQuota(
            packType: _selectedPack!,
            paymentMethod: _selectedPaymentMethod,
            // phoneNumber peut être ajouté ici pour Mobile Money si nécessaire
          );

      // Succès
    } catch (e) {
      // Propager l'erreur pour qu'elle soit gérée par le dialog
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.rechargeYourQuota),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QuotaHistoryScreen(),
                ),
              );
            },
            tooltip: 'Historique des achats',
          ),
        ],
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

            // Grille 2x2 pour les méthodes de paiement mobile
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSizes.spacingMd,
              crossAxisSpacing: AppSizes.spacingMd,
              childAspectRatio: 1.5,
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                final brandColor = Color(method.brandColor);

                return GestureDetector(
                  onTap: () => setState(() => _selectedPaymentMethod = method),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? brandColor.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: isSelected ? brandColor : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: brandColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.phone_android,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingSm),
                        Text(
                          method.shortName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? brandColor
                                    : AppColors.textPrimary,
                              ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle,
                              color: brandColor,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

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
