import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/models/models.dart';
import '../widgets/delivery_card.dart';
import '../../delivery/screens/new_delivery_screen.dart';
import '../../delivery/screens/tracking_screen.dart';
import '../../delivery/screens/deliveries_history_screen.dart';
import '../../statistics/screens/statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Get contextual greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 18) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
  }

  Future<void> _onRefresh() async {
    // TODO: Refresh data from API
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  // User Avatar avec point vert (en ligne)
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.secondary,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.textWhite,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSizes.spacingMd),
                  // Welcome Text with contextual greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_getGreeting()}, Jean !',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          '2 livraisons en cours',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Notification Bell with badge
                NotificationBell(
                  unreadCount: 3, // TODO: Get from provider
                  iconColor: AppColors.secondary,
                ),
              ],
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Card with gradient and stats
                    _buildHeroCard(context),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Quick Actions Grid
                    _buildQuickActions(context),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Active Deliveries Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Livraisons en cours',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Active Deliveries List
                    _buildActiveDeliveries(context),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Recent History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Historique récent',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DeliveriesHistoryScreen(),
                              ),
                            );
                          },
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Recent Deliveries List
                    _buildRecentDeliveries(context),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDeliveries(BuildContext context) {
    // Mock data - will be replaced with real data from provider
    final activeDeliveries = [
      _createMockDelivery(
        id: '1',
        from: 'Cocody Angré, Abidjan',
        to: 'Plateau, Boulevard de la République, Abidjan',
        status: DeliveryStatus.deliveryInProgress,
        date: DateTime.now().subtract(const Duration(minutes: 25)),
        price: 3500,
      ),
      _createMockDelivery(
        id: '2',
        from: 'Marcory Zone 4, Abidjan',
        to: 'Yopougon, Abidjan',
        status: DeliveryStatus.pickupInProgress,
        date: DateTime.now().subtract(const Duration(hours: 1)),
        price: 2800,
      ),
    ];

    if (activeDeliveries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              'Aucune livraison active',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeDeliveries.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.spacingLg),
      itemBuilder: (context, index) {
        return DeliveryCard(
          delivery: activeDeliveries[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackingScreen(
                  deliveryId: activeDeliveries[index].id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentDeliveries(BuildContext context) {
    // Mock data - will be replaced with real data from provider
    // Only show completed deliveries
    final completedDeliveries = [
      _createMockDelivery(
        id: '3',
        from: 'Treichville, Abidjan',
        to: 'Adjamé, Abidjan',
        status: DeliveryStatus.delivered,
        date: DateTime.now().subtract(const Duration(days: 1)),
        price: 2500,
        rating: 5,
        deliveredAt: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(hours: 1, minutes: 25)),
      ),
      _createMockDelivery(
        id: '4',
        from: 'Koumassi, Abidjan',
        to: 'Bingerville, Abidjan',
        status: DeliveryStatus.delivered,
        date: DateTime.now().subtract(const Duration(days: 2)),
        price: 3200,
        rating: 4,
        deliveredAt: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(hours: 2, minutes: 10)),
      ),
    ];

    if (completedDeliveries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              'Aucun historique',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completedDeliveries.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.spacingLg),
      itemBuilder: (context, index) {
        return DeliveryCard(
          delivery: completedDeliveries[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackingScreen(
                  deliveryId: completedDeliveries[index].id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  DeliveryModel _createMockDelivery({
    required String id,
    required String from,
    required String to,
    required DeliveryStatus status,
    required DateTime date,
    required double price,
    int? rating,
    DateTime? deliveredAt,
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
        latitude: 0,
        longitude: 0,
      ),
      deliveryAddress: AddressModel(
        address: to,
        latitude: 0,
        longitude: 0,
      ),
      mode: DeliveryMode.standard,
      status: status,
      price: price,
      createdAt: date,
      rating: rating,
      deliveredAt: deliveredAt,
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    // Mock stats - will be replaced with real data
    final activeDeliveries = 2;
    final monthlyDeliveries = 12;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background illustration (overlay)
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.delivery_dining,
                size: 180,
                color: AppColors.textWhite,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active deliveries badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMd,
                    vertical: AppSizes.paddingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: AppColors.textWhite,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        '$activeDeliveries ${activeDeliveries > 1 ? 'livraisons actives' : 'livraison active'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.spacingLg),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.inventory_2_outlined,
                        value: '$monthlyDeliveries',
                        label: 'Ce mois',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.textWhite.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.access_time,
                        value: '~30 min',
                        label: 'Temps moyen',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textWhite,
          size: 24,
        ),
        const SizedBox(height: AppSizes.spacingSm),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textWhite.withValues(alpha: 0.9),
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        // Row 1: Nouvelle livraison (full width)
        _buildActionButton(
          context,
          icon: Icons.inventory_2_rounded,
          label: AppStrings.newDelivery,
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewDeliveryScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.spacingMd),
        // Row 2: Statistiques (full width)
        _buildActionButton(
          context,
          icon: Icons.bar_chart_rounded,
          label: 'Statistiques',
          color: AppColors.secondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StatisticsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.textWhite,
              size: 24,
            ),
            const SizedBox(width: AppSizes.spacingSm),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
