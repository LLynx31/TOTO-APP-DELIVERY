import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/quota_service.dart';
import '../../shared/models/quota_model.dart';
import '../../shared/widgets/widgets.dart';
import '../quota/providers/quota_provider.dart';
import '../quota/quota_recharge_screen.dart';

/// Écran Portefeuille - Historique des achats de quotas
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _quotaService = QuotaService();
  List<QuotaPurchase> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    print('📜 WalletScreen: Loading quota history...');
    setState(() => _isLoading = true);

    try {
      final transactions = await _quotaService.getAllTransactions();
      print('✅ WalletScreen: Loaded ${transactions.length} transactions');

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      if (transactions.isEmpty) {
        print('⚠️ WalletScreen: No transactions found - showing empty state');
      }
    } catch (e) {
      print('❌ WalletScreen: Error loading transactions: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer le quota actuel depuis le provider
    final currentQuota = ref.watch(quotaProvider).remainingDeliveries;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historique des recharges',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Recharge button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuotaRechargeScreen(
                      currentQuota: currentQuota,
                    ),
                  ),
                );

                // Recharger l'historique si un achat a été effectué
                if (result == true && mounted) {
                  _loadTransactions();
                }
              },
              icon: const Icon(Icons.add_card),
              tooltip: 'Recharger',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState(currentQuota)
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(int currentQuota) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),
            Text(
              'Aucun achat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              'Vous n\'avez pas encore acheté de pack de quotas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuotaRechargeScreen(
                        currentQuota: currentQuota,
                      ),
                    ),
                  );

                  // Recharger l'historique si un achat a été effectué
                  if (result == true && mounted) {
                    _loadTransactions();
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Recharger maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.paddingMd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(QuotaPurchase transaction) {
    final dateFormat = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date et montant
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(transaction.purchasedAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Achat de ${transaction.deliveries} courses',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMd,
                      vertical: AppSizes.paddingSm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      '+${transaction.deliveries}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Divider
              const Divider(),

              const SizedBox(height: AppSizes.spacingSm),

              // Détails
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      icon: Icons.inbox,
                      label: 'Type de pack',
                      value: _getPackTypeName(transaction.packType.name),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingSm),

              _buildDetailRow(
                icon: Icons.payment,
                label: 'Méthode de paiement',
                value: _getPaymentMethodName(transaction.paymentMethod),
              ),

              const SizedBox(height: AppSizes.spacingSm),

              _buildDetailRow(
                icon: Icons.attach_money,
                label: 'Montant',
                value: '${transaction.price.toStringAsFixed(0)} FCFA',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  String _getPackTypeName(String? packType) {
    if (packType == null) return 'Pack inconnu';

    switch (packType.toLowerCase()) {
      case 'basic':
        return 'Pack Basic';
      case 'standard':
        return 'Pack Standard';
      case 'premium':
        return 'Pack Premium';
      case 'custom':
        return 'Pack Personnalisé';
      default:
        return packType;
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMoney:
        return 'MTN Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.wave:
        return 'Wave';
    }
  }
}
