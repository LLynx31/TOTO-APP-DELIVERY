import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_names.dart';
import '../../../widgets/custom_button.dart';

class PaymentResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const PaymentResultScreen({super.key, required this.result});

  bool get isSuccess => result['success'] == true;
  double get amount => result['amount'] ?? 0.0;
  String get method => result['method'] ?? 'unknown';
  String get transactionId => result['transactionId'] ?? '';
  String? get deliveryId => result['deliveryId'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Résultat du paiement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSizes.spacingXl),

            // Icône de résultat avec animation
            _buildResultIcon(),

            const SizedBox(height: AppSizes.spacingLg),

            // Titre et message
            _buildResultMessage(context),

            const SizedBox(height: AppSizes.spacingXl),

            // Détails de la transaction
            _buildTransactionDetails(context),

            const SizedBox(height: AppSizes.spacingLg),

            // Montant
            _buildAmountCard(),

            const SizedBox(height: AppSizes.spacingXl),

            // Boutons d'action
            _buildActionButtons(context),

            if (isSuccess) ...[
              const SizedBox(height: AppSizes.spacingMd),
              _buildInfoBanner(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultIcon() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 80,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          isSuccess ? 'Paiement réussi !' : 'Paiement échoué',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSuccess ? AppColors.success : AppColors.error,
              ),
        ),
        const SizedBox(height: AppSizes.spacingSm),
        Text(
          isSuccess
              ? 'Votre paiement a été traité avec succès'
              : 'Une erreur s\'est produite lors du traitement',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          _buildDetailRow(
            context,
            'ID Transaction',
            transactionId,
            Icons.receipt_long,
          ),
          const Divider(height: AppSizes.spacingMd),
          _buildDetailRow(
            context,
            'Méthode de paiement',
            _getMethodLabel(method),
            Icons.payment,
          ),
          const Divider(height: AppSizes.spacingMd),
          _buildDetailRow(
            context,
            'Date et heure',
            _formatDateTime(DateTime.now()),
            Icons.access_time,
          ),
          if (deliveryId != null) ...[
            const Divider(height: AppSizes.spacingMd),
            _buildDetailRow(
              context,
              'ID Livraison',
              deliveryId!,
              Icons.local_shipping,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuccess
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Montant',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${amount.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        CustomButton(
          text: isSuccess ? 'Retour à l\'accueil' : 'Réessayer',
          onPressed: () {
            if (isSuccess) {
              context.go(RoutePaths.home);
            } else {
              context.pop();
            }
          },
          backgroundColor: isSuccess ? AppColors.primary : AppColors.error,
        ),
        if (!isSuccess) ...[
          const SizedBox(height: AppSizes.spacingMd),
          OutlinedButton(
            onPressed: () => context.go(RoutePaths.home),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingMd,
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
        if (isSuccess && deliveryId != null) ...[
          const SizedBox(height: AppSizes.spacingMd),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Naviguer vers le suivi de la livraison
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation vers le suivi à implémenter'),
                ),
              );
            },
            icon: const Icon(Icons.track_changes),
            label: const Text('Suivre ma livraison'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingMd,
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.info),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppSizes.spacingSm),
          Expanded(
            child: Text(
              'Un reçu de cette transaction a été envoyé à votre adresse email',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'mobileMoney':
        return 'Mobile Money';
      case 'card':
        return 'Carte bancaire';
      case 'cash':
        return 'Espèces';
      default:
        return method;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year à $hour:$minute';
  }
}
