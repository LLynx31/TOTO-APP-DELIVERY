import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../home/widgets/delivery_card.dart';
import 'tracking_screen.dart';

class DeliveriesHistoryScreen extends StatefulWidget {
  const DeliveriesHistoryScreen({super.key});

  @override
  State<DeliveriesHistoryScreen> createState() =>
      _DeliveriesHistoryScreenState();
}

class _DeliveriesHistoryScreenState extends State<DeliveriesHistoryScreen> {
  List<DeliveryModel> _deliveries = [];
  bool _isLoading = true;
  DeliveryStatus? _selectedFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);

    // Simuler appel API
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock data avec adresses ivoiriennes
    _deliveries = [
      _createMockDelivery(
        id: '1',
        from: 'Cocody Angré, Abidjan',
        to: 'Plateau Rue du Commerce, Abidjan',
        status: DeliveryStatus.deliveryInProgress,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        price: 2500,
      ),
      _createMockDelivery(
        id: '2',
        from: 'Yopougon, Abidjan',
        to: 'Marcory Zone 4, Abidjan',
        status: DeliveryStatus.delivered,
        date: DateTime.now().subtract(const Duration(days: 1)),
        price: 1800,
      ),
      _createMockDelivery(
        id: '3',
        from: 'Treichville, Abidjan',
        to: 'Adjamé, Abidjan',
        status: DeliveryStatus.delivered,
        date: DateTime.now().subtract(const Duration(days: 2)),
        price: 1500,
      ),
      _createMockDelivery(
        id: '4',
        from: 'Cocody Riviera, Abidjan',
        to: 'Bingerville, Abidjan',
        status: DeliveryStatus.cancelled,
        date: DateTime.now().subtract(const Duration(days: 5)),
        price: 3200,
      ),
      _createMockDelivery(
        id: '5',
        from: 'Abobo, Abidjan',
        to: 'Port-Bouët, Abidjan',
        status: DeliveryStatus.delivered,
        date: DateTime.now().subtract(const Duration(days: 8)),
        price: 2200,
      ),
    ];

    setState(() => _isLoading = false);
  }

  Future<void> _refreshDeliveries() async {
    await _loadDeliveries();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liste actualisée'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  DeliveryModel _createMockDelivery({
    required String id,
    required String from,
    required String to,
    required DeliveryStatus status,
    required DateTime date,
    required double price,
  }) {
    return DeliveryModel(
      id: id,
      customerId: 'user123',
      package: PackageModel(
        size: PackageSize.medium,
        weight: 2.5,
      ),
      pickupAddress: AddressModel(
        address: from,
        latitude: 5.3599,
        longitude: -4.0083,
      ),
      deliveryAddress: AddressModel(
        address: to,
        latitude: 5.3599,
        longitude: -4.0083,
      ),
      mode: DeliveryMode.standard,
      status: status,
      price: price,
      createdAt: date,
    );
  }

  int get _activeDeliveries => _deliveries.where((d) =>
    d.status == DeliveryStatus.pending ||
    d.status == DeliveryStatus.accepted ||
    d.status == DeliveryStatus.pickupInProgress ||
    d.status == DeliveryStatus.pickedUp ||
    d.status == DeliveryStatus.deliveryInProgress
  ).length;

  List<DeliveryModel> get _filteredDeliveries {
    var filtered = _deliveries;

    // Filtrer par statut
    if (_selectedFilter != null) {
      filtered = filtered.where((d) => d.status == _selectedFilter).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) =>
        d.id.toLowerCase().contains(_searchQuery) ||
        d.pickupAddress.address.toLowerCase().contains(_searchQuery) ||
        d.deliveryAddress.address.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    // Trier
    switch (_sortOption) {
      case SortOption.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.priceDesc:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.priceAsc:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
    }

    return filtered;
  }

  Map<String, List<DeliveryModel>> get _groupedDeliveries {
    final grouped = <String, List<DeliveryModel>>{};
    final now = DateTime.now();

    for (var delivery in _filteredDeliveries) {
      final date = delivery.createdAt;
      String key;

      // Aujourd'hui
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        key = 'Aujourd\'hui';
      }
      // Hier
      else if (date.year == now.year &&
               date.month == now.month &&
               date.day == now.day - 1) {
        key = 'Hier';
      }
      // Cette semaine
      else if (now.difference(date).inDays < 7) {
        key = 'Cette semaine';
      }
      // Ce mois
      else if (date.year == now.year && date.month == now.month) {
        key = 'Ce mois';
      }
      // Plus ancien
      else {
        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
                       'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
        key = '${months[date.month - 1]} ${date.year}';
      }

      grouped.putIfAbsent(key, () => []).add(delivery);
    }

    return grouped;
  }

  void _navigateToTracking(String deliveryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingScreen(deliveryId: deliveryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Badge livraisons actives
          if (_activeDeliveries > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_activeDeliveries en cours',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

          // Menu tri
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier',
            onSelected: (option) {
              setState(() => _sortOption = option);
            },
            itemBuilder: (context) => SortOption.values.map((option) =>
              PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (_sortOption == option)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check, size: 20, color: AppColors.primary),
                      ),
                    Text(option.label),
                  ],
                ),
              ),
            ).toList(),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),

          // Filtres par statut
          _buildFilterChips(),

          const SizedBox(height: AppSizes.spacingSm),

          // Liste avec pull-to-refresh
          Expanded(
            child: _isLoading
              ? _buildLoadingState()
              : _buildDeliveriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        AppSizes.paddingMd,
        AppSizes.paddingLg,
        AppSizes.paddingMd,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Rechercher par ID ou adresse...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Toutes',
            count: _deliveries.length,
            isSelected: _selectedFilter == null,
            onTap: () => setState(() => _selectedFilter = null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'En cours',
            count: _deliveries.where((d) =>
              d.status == DeliveryStatus.deliveryInProgress).length,
            isSelected: _selectedFilter == DeliveryStatus.deliveryInProgress,
            onTap: () => setState(() =>
              _selectedFilter = DeliveryStatus.deliveryInProgress),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Livrées',
            count: _deliveries.where((d) =>
              d.status == DeliveryStatus.delivered).length,
            isSelected: _selectedFilter == DeliveryStatus.delivered,
            onTap: () => setState(() =>
              _selectedFilter = DeliveryStatus.delivered),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Annulées',
            count: _deliveries.where((d) =>
              d.status == DeliveryStatus.cancelled).length,
            isSelected: _selectedFilter == DeliveryStatus.cancelled,
            onTap: () => setState(() =>
              _selectedFilter = DeliveryStatus.cancelled),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                  ? AppColors.textWhite.withValues(alpha: 0.3)
                  : AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      itemCount: 3,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmer(width: 80, height: 20),
                _buildShimmer(width: 60, height: 24, radius: 12),
              ],
            ),
            const SizedBox(height: 12),
            _buildShimmer(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            _buildShimmer(width: double.infinity, height: 16),
            const Spacer(),
            _buildShimmer(width: 100, height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildDeliveriesList() {
    if (_filteredDeliveries.isEmpty) {
      return _buildEnhancedEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshDeliveries,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        itemCount: _calculateTotalItems(),
        itemBuilder: (context, index) {
          final entry = _getSectionAndIndex(index);

          if (entry.isHeader) {
            // Section header
            return Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 12,
                left: 4,
              ),
              child: Text(
                entry.sectionKey,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          } else {
            // Delivery card
            final delivery = entry.delivery!;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
              child: DeliveryCard(
                delivery: delivery,
                onTap: () => _navigateToTracking(delivery.id),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedFilter != null;

    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 300,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasFilters ? Icons.search_off : Icons.inbox_outlined,
                      size: 60,
                      color: AppColors.textTertiary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    hasFilters ? 'Aucun résultat' : 'Aucune livraison',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Message
                  Text(
                    hasFilters
                      ? 'Essayez de modifier vos critères de recherche'
                      : 'Vous n\'avez pas encore effectué de livraison',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Action
                  if (hasFilters)
                    CustomButton(
                      text: 'Réinitialiser les filtres',
                      onPressed: () {
                        setState(() {
                          _selectedFilter = null;
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      variant: ButtonVariant.outline,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _calculateTotalItems() {
    int count = 0;
    for (var section in _groupedDeliveries.entries) {
      count++; // Header
      count += section.value.length; // Items
    }
    return count;
  }

  ({bool isHeader, String sectionKey, DeliveryModel? delivery})
    _getSectionAndIndex(int globalIndex) {
    int currentIndex = 0;

    for (var entry in _groupedDeliveries.entries) {
      // Header
      if (currentIndex == globalIndex) {
        return (
          isHeader: true,
          sectionKey: entry.key,
          delivery: null,
        );
      }
      currentIndex++;

      // Items
      for (var delivery in entry.value) {
        if (currentIndex == globalIndex) {
          return (
            isHeader: false,
            sectionKey: entry.key,
            delivery: delivery,
          );
        }
        currentIndex++;
      }
    }

    throw RangeError('Index out of range');
  }
}

enum SortOption {
  dateDesc('Plus récentes'),
  dateAsc('Plus anciennes'),
  priceDesc('Prix décroissant'),
  priceAsc('Prix croissant');

  final String label;
  const SortOption(this.label);
}
