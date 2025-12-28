import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/delivery.dart';
import '../../../providers/delivery_provider.dart';
import '../../../widgets/delivery_card.dart';

/// Type de filtre pour les livraisons
enum DeliveryFilter {
  all,
  active,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case DeliveryFilter.all:
        return 'Toutes';
      case DeliveryFilter.active:
        return 'En cours';
      case DeliveryFilter.delivered:
        return 'Livrées';
      case DeliveryFilter.cancelled:
        return 'Annulées';
    }
  }

  DeliveryStatus? get status {
    switch (this) {
      case DeliveryFilter.all:
        return null;
      case DeliveryFilter.active:
        return null; // Filtré dans le code
      case DeliveryFilter.delivered:
        return DeliveryStatus.delivered;
      case DeliveryFilter.cancelled:
        return DeliveryStatus.cancelled;
    }
  }
}

class DeliveriesListScreen extends ConsumerStatefulWidget {
  const DeliveriesListScreen({super.key});

  @override
  ConsumerState<DeliveriesListScreen> createState() => _DeliveriesListScreenState();
}

class _DeliveriesListScreenState extends ConsumerState<DeliveriesListScreen> {
  DeliveryFilter _selectedFilter = DeliveryFilter.all;

  @override
  void initState() {
    super.initState();
    // Charger les livraisons au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeliveries();
    });
  }

  void _loadDeliveries() {
    ref.read(deliveriesProvider.notifier).loadDeliveries(
          status: _selectedFilter.status,
        );
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesState = ref.watch(deliveriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.deliveries),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtres
          _buildFilterChips(),

          const SizedBox(height: AppSizes.spacingSm),

          // Liste des livraisons
          Expanded(
            child: _buildContent(deliveriesState),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          right: AppSizes.paddingMd,
          bottom: AppSizes.paddingMd,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.goToCreateDelivery(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nouvelle livraison',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: DeliveryFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.spacingMd),
            child: ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(filter.label),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _loadDeliveries();
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(DeliveriesState state) {
    if (state is DeliveriesLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is DeliveriesError) {
      return _buildErrorState(state.message);
    }

    if (state is DeliveriesLoaded) {
      final deliveries = _filterDeliveries(state.deliveries);

      if (deliveries.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(deliveriesProvider.notifier).refresh();
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(
            left: AppSizes.paddingLg,
            right: AppSizes.paddingLg,
            top: AppSizes.paddingMd,
            bottom: 100, // Espace pour le FAB
          ),
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
              child: DeliveryCard(
                delivery: delivery,
                onTap: () => _handleDeliveryTap(delivery),
              ),
            );
          },
        ),
      );
    }

    return _buildEmptyState();
  }

  List<Delivery> _filterDeliveries(List<Delivery> deliveries) {
    if (_selectedFilter == DeliveryFilter.active) {
      return deliveries.where((d) => d.isActive).toList();
    }
    return deliveries;
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case DeliveryFilter.all:
        message = 'Aucune livraison';
        icon = Icons.inbox_outlined;
        break;
      case DeliveryFilter.active:
        message = 'Aucune livraison en cours';
        icon = Icons.local_shipping_outlined;
        break;
      case DeliveryFilter.delivered:
        message = 'Aucune livraison terminée';
        icon = Icons.check_circle_outline;
        break;
      case DeliveryFilter.cancelled:
        message = 'Aucune livraison annulée';
        icon = Icons.cancel_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              'Créez une nouvelle livraison pour commencer',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.goToCreateDelivery(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nouvelle livraison',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLg,
                    vertical: AppSizes.paddingMd + 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),
            Text(
              'Une erreur s\'est produite',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadDeliveries,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLg,
                    vertical: AppSizes.paddingMd + 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeliveryTap(Delivery delivery) {
    // Si la livraison est active, naviguer vers le tracking
    if (delivery.isActive) {
      context.goToTracking(delivery.id);
    } else {
      // Sinon, afficher les détails
      _showDeliveryDetailsDialog(delivery);
    }
  }

  void _showDeliveryDetailsDialog(Delivery delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getStatusTitle(delivery.status)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('De', delivery.pickupLocation.address),
            const SizedBox(height: AppSizes.spacingSm),
            _buildDetailRow('Vers', delivery.deliveryLocation.address),
            const SizedBox(height: AppSizes.spacingSm),
            _buildDetailRow('Destinataire', delivery.package.receiverName),
            const SizedBox(height: AppSizes.spacingSm),
            _buildDetailRow('Téléphone', delivery.package.receiverPhone),
            if (delivery.package.description != null) ...[
              const SizedBox(height: AppSizes.spacingSm),
              _buildDetailRow('Description', delivery.package.description!),
            ],
            const SizedBox(height: AppSizes.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${delivery.price.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (delivery.status == DeliveryStatus.pending)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleCancelDelivery(delivery);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Annuler'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getStatusTitle(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.accepted:
        return 'Acceptée';
      case DeliveryStatus.pickupInProgress:
        return 'Ramassage en cours';
      case DeliveryStatus.pickedUp:
        return 'Ramassée';
      case DeliveryStatus.deliveryInProgress:
        return 'Livraison en cours';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  Future<void> _handleCancelDelivery(Delivery delivery) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la livraison'),
        content: const Text(
          'Voulez-vous vraiment annuler cette livraison ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(deliveriesProvider.notifier)
          .cancelDelivery(delivery.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Livraison annulée avec succès'
                  : 'Erreur lors de l\'annulation',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}
