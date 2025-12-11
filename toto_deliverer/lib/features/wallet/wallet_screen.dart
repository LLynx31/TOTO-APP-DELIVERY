import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/widgets/widgets.dart';
import '../quota/quota_recharge_screen.dart';
import 'widgets/quota_purchase_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Mock data - À remplacer par les données réelles du backend
  final int _currentQuota = 5; // Current remaining quota

  // Only quota purchase transactions
  final List<TransactionModel> _quotaPurchases = [
    TransactionModel(
      id: 'TXN003',
      delivererId: 'DLV001',
      amount: 9500,
      type: TransactionType.quotaPurchase,
      description: 'Achat Pack Standard - 10 livraisons',
      status: TransactionStatus.completed,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 'TXN005',
      delivererId: 'DLV001',
      amount: 15500,
      type: TransactionType.quotaPurchase,
      description: 'Achat Pack Pro - 20 livraisons',
      status: TransactionStatus.completed,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionModel(
      id: 'TXN006',
      delivererId: 'DLV001',
      amount: 5000,
      type: TransactionType.quotaPurchase,
      description: 'Achat Pack Basique - 5 livraisons',
      status: TransactionStatus.completed,
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TransactionModel(
      id: 'TXN007',
      delivererId: 'DLV001',
      amount: 32000,
      type: TransactionType.quotaPurchase,
      description: 'Achat Pack Premium - 50 livraisons',
      status: TransactionStatus.pending,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  void _rechargeQuota() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotaRechargeScreen(
          currentQuota: _currentQuota,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _rechargeQuota,
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
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
          await Future.delayed(const Duration(seconds: 1));
        },
        child: _quotaPurchases.isEmpty
            ? Center(
                child: EmptyState(
                  icon: Icons.history,
                  title: 'Aucune recharge effectuée',
                  message: 'Vos recharges de quotas apparaîtront ici',
                  buttonText: 'Recharger maintenant',
                  onButtonPressed: _rechargeQuota,
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.spacingMd),
                          Expanded(
                            child: Text(
                              'Historique de vos achats de packs de livraison',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.info,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingLg),

                    // Recharge History Header with count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mes recharges',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            '${_quotaPurchases.length}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Quota Purchase List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quotaPurchases.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSizes.spacingMd),
                      itemBuilder: (context, index) {
                        final purchase = _quotaPurchases[index];
                        return QuotaPurchaseCard(transaction: purchase);
                      },
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Bottom recharge button
                    CustomButton(
                      text: 'Recharger mes quotas',
                      onPressed: _rechargeQuota,
                      icon: const Icon(Icons.add_card, size: 20),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
