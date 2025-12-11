import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/delivery_provider.dart';
import '../../models/delivery_model.dart';
import 'package:intl/intl.dart';

class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  final String deliveryId;

  const DeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState
    extends ConsumerState<DeliveryDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(deliveryProvider(widget.deliveryId).notifier).loadDelivery(widget.deliveryId);
    });
  }

  Future<void> _handleCancel(DeliveryModel delivery) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la livraison'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette livraison ? '
          'Une livraison vous sera remboursée sur votre forfait.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(deliveryProvider(widget.deliveryId).notifier)
        .cancelDelivery(widget.deliveryId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison annulée'),
          backgroundColor: Colors.green,
        ),
      );
      // Rafraîchir la liste
      ref.read(deliveryListProvider.notifier).refresh();
    } else {
      final error = ref.read(deliveryProvider(widget.deliveryId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur lors de l\'annulation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.accepted:
        return Colors.blue;
      case DeliveryStatus.pickupInProgress:
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.deliveryInProgress:
        return Colors.purple;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider(widget.deliveryId));
    final delivery = deliveryState.delivery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la livraison'),
        actions: [
          if (delivery != null &&
              delivery.status == DeliveryStatus.pending)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _handleCancel(delivery),
            ),
        ],
      ),
      body: deliveryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : deliveryState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(deliveryState.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(deliveryProvider(widget.deliveryId).notifier)
                              .loadDelivery(widget.deliveryId);
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : delivery == null
                  ? const Center(child: Text('Livraison introuvable'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(deliveryProvider(widget.deliveryId).notifier)
                            .loadDelivery(widget.deliveryId);
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Status card
                          Card(
                            color: _getStatusColor(delivery.status).withAlpha(51),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    _getStatusIcon(delivery.status),
                                    size: 48,
                                    color: _getStatusColor(delivery.status),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    delivery.statusLabel,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(delivery.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price and distance
                          Row(
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.attach_money,
                                  title: 'Prix',
                                  value: '${delivery.price.toStringAsFixed(2)} USD',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.route,
                                  title: 'Distance',
                                  value: '${delivery.distanceKm.toStringAsFixed(1)} km',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Pickup section
                          _SectionTitle(title: 'Point de ramassage'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(delivery.pickupAddress)),
                                    ],
                                  ),
                                  if (delivery.pickupPhone != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 20),
                                        const SizedBox(width: 8),
                                        Text(delivery.pickupPhone!),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Delivery section
                          _SectionTitle(title: 'Point de livraison'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(delivery.deliveryAddress)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 20),
                                      const SizedBox(width: 8),
                                      Text(delivery.receiverName),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 20),
                                      const SizedBox(width: 8),
                                      Text(delivery.deliveryPhone),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Package info
                          _SectionTitle(title: 'Informations du colis'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(delivery.packageDescription)),
                                    ],
                                  ),
                                  if (delivery.packageWeight != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.scale, size: 20),
                                        const SizedBox(width: 8),
                                        Text('${delivery.packageWeight} kg'),
                                      ],
                                    ),
                                  ],
                                  if (delivery.specialInstructions != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.note, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(delivery.specialInstructions!)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Timeline
                          _SectionTitle(title: 'Historique'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _TimelineItem(
                                    title: 'Créée',
                                    date: delivery.createdAt,
                                    isCompleted: true,
                                  ),
                                  if (delivery.acceptedAt != null)
                                    _TimelineItem(
                                      title: 'Acceptée',
                                      date: delivery.acceptedAt!,
                                      isCompleted: true,
                                    ),
                                  if (delivery.pickedUpAt != null)
                                    _TimelineItem(
                                      title: 'Colis récupéré',
                                      date: delivery.pickedUpAt!,
                                      isCompleted: true,
                                    ),
                                  if (delivery.deliveredAt != null)
                                    _TimelineItem(
                                      title: 'Livrée',
                                      date: delivery.deliveredAt!,
                                      isCompleted: true,
                                      isLast: true,
                                    ),
                                  if (delivery.cancelledAt != null)
                                    _TimelineItem(
                                      title: 'Annulée',
                                      date: delivery.cancelledAt!,
                                      isCompleted: true,
                                      isLast: true,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Icons.pending;
      case DeliveryStatus.accepted:
        return Icons.check_circle;
      case DeliveryStatus.pickupInProgress:
        return Icons.directions_walk;
      case DeliveryStatus.pickedUp:
        return Icons.inventory_2;
      case DeliveryStatus.deliveryInProgress:
        return Icons.local_shipping;
      case DeliveryStatus.delivered:
        return Icons.done_all;
      case DeliveryStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final DateTime date;
  final bool isCompleted;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 20,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                dateFormat.format(date),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
