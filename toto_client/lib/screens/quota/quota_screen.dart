import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quota_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../models/quota_model.dart';
import 'package:intl/intl.dart';

class QuotaScreen extends ConsumerStatefulWidget {
  const QuotaScreen({super.key});

  @override
  ConsumerState<QuotaScreen> createState() => _QuotaScreenState();
}

class _QuotaScreenState extends ConsumerState<QuotaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(packagesProvider.notifier).loadPackages();
      ref.read(quotasProvider.notifier).loadQuotas();
    });
  }

  Future<void> _handlePurchase(QuotaPackageModel package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acheter un forfait'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forfait: ${package.name}'),
            Text('Livraisons: ${package.deliveries}'),
            Text('Prix: ${package.priceUsd.toStringAsFixed(2)} USD'),
            if (package.validityDays != null)
              Text('Validité: ${package.validityDays} jours'),
            const SizedBox(height: 16),
            const Text(
              'Voulez-vous acheter ce forfait ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Acheter'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(quotasProvider.notifier)
        .purchasePackage(package.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Forfait acheté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      // Rafraîchir la liste des livraisons
      ref.read(deliveryListProvider.notifier).refresh();
    } else {
      final error = ref.read(quotasProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur lors de l\'achat'),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(quotasProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesState = ref.watch(packagesProvider);
    final quotasState = ref.watch(quotasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forfaits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(packagesProvider.notifier).refresh();
              ref.read(quotasProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(packagesProvider.notifier).refresh();
          await ref.read(quotasProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active quota section
            if (quotasState.activeQuota != null) ...[
              Text(
                'Mon forfait actif',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _ActiveQuotaCard(quota: quotasState.activeQuota!),
              const SizedBox(height: 24),
            ],

            // Available packages
            Text(
              'Forfaits disponibles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (packagesState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (packagesState.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(packagesState.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(packagesProvider.notifier).refresh();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            else if (packagesState.packages.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aucun forfait disponible'),
                ),
              )
            else
              ...packagesState.packages.map(
                (package) => _PackageCard(
                  package: package,
                  onPurchase: () => _handlePurchase(package),
                ),
              ),

            const SizedBox(height: 24),

            // My quotas history
            if (quotasState.quotas.isNotEmpty) ...[
              Text(
                'Historique de mes forfaits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...quotasState.quotas.map(
                (quota) => _QuotaHistoryCard(quota: quota),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveQuotaCard extends StatelessWidget {
  final ClientQuotaModel quota;

  const _ActiveQuotaCard({required this.quota});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: Colors.blue.shade700, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quota.package?.name ?? 'Forfait actif',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (quota.package?.description != null)
                        Text(
                          quota.package!.description!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _QuotaInfoItem(
                    icon: Icons.delivery_dining,
                    label: 'Total',
                    value: '${quota.totalDeliveries}',
                  ),
                ),
                Expanded(
                  child: _QuotaInfoItem(
                    icon: Icons.check_circle,
                    label: 'Utilisées',
                    value: '${quota.usedDeliveries}',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _QuotaInfoItem(
                    icon: Icons.inventory,
                    label: 'Restantes',
                    value: '${quota.remainingDeliveries}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (quota.expiresAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Expire le ${dateFormat.format(quota.expiresAt!)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  if (quota.isExpired)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Expiré',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuotaInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _QuotaInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.blue.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final QuotaPackageModel package;
  final VoidCallback onPurchase;

  const _PackageCard({
    required this.package,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (package.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          package.description!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      package.priceUsd.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'USD',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.delivery_dining, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('${package.deliveries} livraisons'),
                if (package.validityDays != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('${package.validityDays} jours'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPurchase,
                child: const Text('Acheter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaHistoryCard extends StatelessWidget {
  final ClientQuotaModel quota;

  const _QuotaHistoryCard({required this.quota});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: quota.isActive ? Colors.green.shade100 : Colors.grey.shade200,
          child: Icon(
            Icons.card_membership,
            color: quota.isActive ? Colors.green.shade700 : Colors.grey.shade600,
          ),
        ),
        title: Text(quota.package?.name ?? 'Forfait'),
        subtitle: Text(
          'Acheté le ${dateFormat.format(quota.purchasedAt)} • '
          '${quota.usedDeliveries}/${quota.totalDeliveries} utilisées',
        ),
        trailing: quota.isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Actif',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
