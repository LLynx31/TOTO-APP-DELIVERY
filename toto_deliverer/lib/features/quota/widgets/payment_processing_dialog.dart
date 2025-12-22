import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Dialog montrant les étapes de traitement du paiement
class PaymentProcessingDialog extends StatefulWidget {
  final Future<void> Function() onProcess;

  const PaymentProcessingDialog({
    super.key,
    required this.onProcess,
  });

  @override
  State<PaymentProcessingDialog> createState() => _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<PaymentProcessingDialog> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Connexion au service de paiement...',
    'Traitement de la transaction...',
    'Validation du paiement...',
  ];

  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    try {
      // Étape 1: Connexion (1.5 secondes)
      setState(() => _currentStep = 0);
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Étape 2: Traitement (2 secondes)
      setState(() => _currentStep = 1);
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return;

      // Étape 3: Validation (1.5 secondes)
      setState(() => _currentStep = 2);
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Appeler la fonction de traitement (appel API réel)
      await widget.onProcess();

      if (!mounted) return;

      // Fermer le dialog après succès
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Empêcher la fermeture pendant le traitement
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation de chargement
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Titre
            Text(
              'Traitement en cours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Liste des étapes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_steps.length, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                final isPending = index > _currentStep;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
                  child: Row(
                    children: [
                      // Icône d'état
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.primary
                                  : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : isCurrent
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                        ),
                      ),

                      const SizedBox(width: AppSizes.spacingSm),

                      // Texte de l'étape
                      Expanded(
                        child: Text(
                          _steps[index],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isPending
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Message d'information
            Text(
              'Veuillez patienter...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
