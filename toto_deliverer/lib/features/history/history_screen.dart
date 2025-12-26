import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/utils/error_messages.dart';
import '../../shared/models/delivery_model.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/history_filters_sheet.dart';
import 'widgets/history_stats_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Delivery history - Loaded from API
  List<DeliveryModel> _completedDeliveries = [];
  List<DeliveryModel> _cancelledDeliveries = [];

  // Filter state
  String? _selectedPeriod;
  DeliveryMode? _selectedMode;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      print('📦 HistoryScreen: Chargement de l\'historique...');

      // TODO: Implémenter getDeliveryHistory() dans HybridDeliveryService
      // Pour l'instant, on simule avec des listes vides
      // final history = await _hybridDeliveryService.getDeliveryHistory();

      if (!mounted) return;

      setState(() {
        // _completedDeliveries = history.where((d) => d.status == DeliveryStatus.delivered).toList();
        // _cancelledDeliveries = history.where((d) => d.status == DeliveryStatus.cancelled).toList();
        _completedDeliveries = [];
        _cancelledDeliveries = [];
      });

      print('✅ HistoryScreen: Historique chargé');
    } catch (e) {
      print('❌ HistoryScreen: Erreur lors du chargement: $e');
      if (!mounted) return;

      ToastUtils.showError(
        context,
        ErrorMessages.fromException(e),
        title: 'Erreur de chargement',
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryFiltersSheet(
        selectedPeriod: _selectedPeriod,
        selectedMode: _selectedMode,
        searchQuery: _searchQuery,
        onApply: (period, mode, query) {
          setState(() {
            _selectedPeriod = period;
            _selectedMode = mode;
            _searchQuery = query;
          });
        },
      ),
    );
  }

  List<DeliveryModel> _applyFilters(List<DeliveryModel> deliveries) {
    var filtered = deliveries;

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((d) =>
        d.id.toLowerCase().contains(_searchQuery!.toLowerCase())
      ).toList();
    }

    // Filter by mode
    if (_selectedMode != null) {
      filtered = filtered.where((d) => d.mode == _selectedMode).toList();
    }

    // Filter by period
    if (_selectedPeriod != null) {
      final now = DateTime.now();
      filtered = filtered.where((d) {
        if (_selectedPeriod == 'Aujourd\'hui') {
          return d.createdAt.year == now.year &&
                 d.createdAt.month == now.month &&
                 d.createdAt.day == now.day;
        } else if (_selectedPeriod == 'Cette semaine') {
          final weekAgo = now.subtract(const Duration(days: 7));
          return d.createdAt.isAfter(weekAgo);
        } else if (_selectedPeriod == 'Ce mois') {
          return d.createdAt.year == now.year &&
                 d.createdAt.month == now.month;
        }
        return true; // 'Tous'
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedPeriod != null ||
                            _selectedMode != null ||
                            (_searchQuery != null && _searchQuery!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.history,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Terminées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeliveryList(_completedDeliveries, DeliveryStatus.delivered),
          _buildDeliveryList(_cancelledDeliveries, DeliveryStatus.cancelled),
        ],
      ),
    );
  }

  Widget _buildDeliveryList(List<DeliveryModel> deliveries, DeliveryStatus status) {
    // Apply filters
    final filteredDeliveries = _applyFilters(deliveries);

    // Calculate stats
    final totalEarned = filteredDeliveries.fold<double>(
      0, (sum, d) => sum + d.price
    );
    final totalDeliveries = filteredDeliveries.length;
    final successRate = deliveries.isEmpty
        ? 0.0
        : (filteredDeliveries.where((d) => d.status == DeliveryStatus.delivered).length /
           deliveries.length) * 100;

    if (deliveries.isEmpty) {
      return EmptyState(
        icon: status == DeliveryStatus.delivered
            ? Icons.check_circle_outline
            : Icons.cancel_outlined,
        title: status == DeliveryStatus.delivered
            ? 'Aucune livraison terminée'
            : 'Aucune livraison annulée',
        message: status == DeliveryStatus.delivered
            ? 'Vos livraisons terminées apparaîtront ici'
            : 'Vos livraisons annulées apparaîtront ici',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: Column(
        children: [
          // Stats Card
          HistoryStatsCard(
            totalEarned: totalEarned,
            totalDeliveries: totalDeliveries,
            successRate: successRate,
          ),

          // Delivery List
          Expanded(
            child: filteredDeliveries.isEmpty
                ? EmptyState(
                    icon: Icons.filter_list_off,
                    title: 'Aucun résultat',
                    message: 'Aucune livraison ne correspond aux filtres sélectionnés',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    itemCount: filteredDeliveries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.spacingMd),
                    itemBuilder: (context, index) {
                      final delivery = filteredDeliveries[index];
                      return _DeliveryHistoryCard(delivery: delivery);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryHistoryCard extends StatelessWidget {
  final DeliveryModel delivery;

  const _DeliveryHistoryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final bool isDelivered = delivery.status == DeliveryStatus.delivered;
    final DateTime? completedDate = isDelivered
        ? delivery.deliveredAt
        : delivery.createdAt; // Use createdAt for cancelled deliveries

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to delivery details
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    delivery.id,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDelivered
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      isDelivered ? 'Terminée' : 'Annulée',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDelivered ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMd),

              // Date
              if (completedDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacingSm),
                    Text(
                      DateFormat('dd/MM/yyyy à HH:mm').format(completedDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSizes.spacingMd),

              // Visual Timeline with Addresses
              _buildTimeline(context),
              const SizedBox(height: AppSizes.spacingMd),

              // Footer: Price and Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingSm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: delivery.mode == DeliveryMode.express
                              ? AppColors.express.withValues(alpha: 0.1)
                              : AppColors.standard.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          delivery.mode == DeliveryMode.express ? 'Express' : 'Standard',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: delivery.mode == DeliveryMode.express
                                    ? AppColors.express
                                    : AppColors.standard,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        '${delivery.package.weight} kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    '${delivery.price} FCFA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              // Additional Info (Rating and Delivery Time for completed deliveries)
              if (isDelivered) ...[
                const SizedBox(height: AppSizes.spacingMd),
                const Divider(),
                const SizedBox(height: AppSizes.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Customer Rating (Mock data - à remplacer)
                    _buildExtraInfo(
                      context: context,
                      icon: Icons.star,
                      label: 'Note client',
                      value: '4.5',
                      color: AppColors.warning,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.border,
                    ),
                    // Delivery Time (Mock calculation)
                    _buildExtraInfo(
                      context: context,
                      icon: Icons.timer,
                      label: 'Temps',
                      value: delivery.deliveredAt != null
                          ? _formatDeliveryDuration(
                              delivery.deliveredAt!.difference(delivery.createdAt))
                          : '-',
                      color: AppColors.info,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDeliveryDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    }
    return '${duration.inMinutes}min';
  }

  Widget _buildTimeline(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.success,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.success,
              ),
            ),
            Container(
              width: 2,
              height: 30,
              color: AppColors.border,
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.flag,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSizes.spacingMd),

        // Addresses
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup
              Text(
                'Départ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                delivery.pickupAddress.address,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.spacingMd),

              // Delivery
              Text(
                'Arrivée',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                delivery.deliveryAddress.address,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtraInfo({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
