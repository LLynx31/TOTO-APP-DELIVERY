import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/simulation_service.dart';
import '../../shared/models/delivery_model.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/widgets.dart';
import '../quota/quota_recharge_screen.dart';
import 'course_details_screen.dart';
import 'widgets/available_course_card.dart';
import 'widgets/status_quota_card.dart';
import 'widgets/daily_stats_card.dart';
import 'widgets/course_filters.dart';
import 'widgets/course_skeleton.dart';
import 'widgets/quick_actions_fab.dart';
import 'widgets/blocked_course_overlay.dart';
import 'widgets/quick_stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOnline = false;
  int _remainingDeliveries = 5;
  final int _totalQuota = 20;
  final bool _isLoading = false;

  // Stats du jour
  final int _completedToday = 12;
  final double _earningsToday = 42000; // Gains du jour en FCFA
  final double _rating = 4.8;
  final Duration _timeOnline = Duration(hours: 6, minutes: 23);

  // Filtres
  DeliveryMode? _selectedMode;
  CourseSortType? _selectedSort;

  // Mock data - À remplacer par les données réelles du backend
  // NOTE: Seulement UNE course en cours à la fois (système de livraison unique)
  final List<DeliveryModel> _availableCourses = [
    // UNE SEULE course en cours - En route vers le pickup (pour tester le scan QR de récupération)
    // Commentez/décommentez pour tester différents états
    DeliveryModel(
      id: 'DEL001ABC',
      customerId: 'USER001',
      package: PackageModel(
        size: PackageSize.medium,
        weight: 2.5,
        description: 'Documents importants et livres',
        photoUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      ),
      pickupAddress: AddressModel(
        address: 'Rue de la République, Plateau, Abidjan',
        latitude: 5.316667,
        longitude: -4.033333,
      ),
      deliveryAddress: AddressModel(
        address: 'Boulevard Latrille, Cocody, Abidjan',
        latitude: 5.350000,
        longitude: -3.983333,
      ),
      mode: DeliveryMode.standard,
      price: 3500,
      status: DeliveryStatus.pickupInProgress,
      hasInsurance: false,
      createdAt: DateTime.now().subtract(Duration(minutes: 15)),
      acceptedAt: DateTime.now().subtract(Duration(minutes: 15)),
      delivererId: 'DELIVERER001',
    ),

    // Courses disponibles (pending) - Plusieurs pour tester les filtres
    DeliveryModel(
      id: 'DEL002XYZ',
      customerId: 'USER002',
      package: PackageModel(
        size: PackageSize.small,
        weight: 1.0,
        description: 'Petit colis fragile - Électronique',
        photoUrl: 'https://images.unsplash.com/photo-1607166452427-7e4477079cb9?w=400',
      ),
      pickupAddress: AddressModel(
        address: 'Avenue Chardy, Marcory, Abidjan',
        latitude: 5.283333,
        longitude: -3.983333,
      ),
      deliveryAddress: AddressModel(
        address: 'Rue des Jardins, Deux Plateaux, Abidjan',
        latitude: 5.366667,
        longitude: -4.000000,
      ),
      mode: DeliveryMode.express,
      price: 4500,
      status: DeliveryStatus.pending,
      hasInsurance: false,
      createdAt: DateTime.now().subtract(Duration(minutes: 2)),
    ),
    DeliveryModel(
      id: 'DEL003MNO',
      customerId: 'USER003',
      package: PackageModel(
        size: PackageSize.large,
        weight: 5.0,
        description: 'Carton de vêtements',
        photoUrl: 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=400',
      ),
      pickupAddress: AddressModel(
        address: 'Zone 4, Marcory, Abidjan',
        latitude: 5.275000,
        longitude: -3.993333,
      ),
      deliveryAddress: AddressModel(
        address: 'Angré 8ème tranche, Abidjan',
        latitude: 5.400000,
        longitude: -3.950000,
      ),
      mode: DeliveryMode.standard,
      price: 5000,
      status: DeliveryStatus.pending,
      hasInsurance: true,
      createdAt: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    DeliveryModel(
      id: 'DEL004PQR',
      customerId: 'USER004',
      package: PackageModel(
        size: PackageSize.medium,
        weight: 3.0,
        description: 'Matériel de bureau',
      ),
      pickupAddress: AddressModel(
        address: 'Treichville, Centre commercial, Abidjan',
        latitude: 5.300000,
        longitude: -4.016667,
      ),
      deliveryAddress: AddressModel(
        address: 'Yopougon, Nouveau quartier, Abidjan',
        latitude: 5.333333,
        longitude: -4.083333,
      ),
      mode: DeliveryMode.express,
      price: 4000,
      status: DeliveryStatus.pending,
      hasInsurance: false,
      createdAt: DateTime.now(),
    ),
    DeliveryModel(
      id: 'DEL005STU',
      customerId: 'USER005',
      package: PackageModel(
        size: PackageSize.small,
        weight: 0.5,
        description: 'Enveloppe urgente',
      ),
      pickupAddress: AddressModel(
        address: 'Adjamé, Marché, Abidjan',
        latitude: 5.366667,
        longitude: -4.016667,
      ),
      deliveryAddress: AddressModel(
        address: 'Bingerville, Centre-ville',
        latitude: 5.350000,
        longitude: -3.900000,
      ),
      mode: DeliveryMode.express,
      price: 3000,
      status: DeliveryStatus.pending,
      hasInsurance: false,
      createdAt: DateTime.now().subtract(Duration(minutes: 1)),
    ),
  ];

  void _toggleOnlineStatus() {
    if (_remainingDeliveries > 0) {
      setState(() {
        _isOnline = !_isOnline;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isOnline
                ? 'Vous êtes maintenant en ligne'
                : 'Vous êtes maintenant hors ligne',
          ),
          backgroundColor: _isOnline ? AppColors.success : AppColors.offline,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rechargez votre quota pour passer en ligne'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _rechargeQuota() async {
    // Navigate to quota recharge screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotaRechargeScreen(
          currentQuota: _remainingDeliveries,
        ),
      ),
    );

    // Refresh quota if purchase was successful
    if (result != null && mounted) {
      setState(() {
        // TODO: Update with actual new quota from backend
        _remainingDeliveries += 5; // Placeholder
      });
    }
  }

  void _viewCourseDetails(DeliveryModel delivery) async {
    // Block acceptance of new courses if there's already an ongoing delivery
    if (_ongoingCourses.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vous avez déjà une course en cours. Terminez-la avant d\'en accepter une nouvelle.',
          ),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: 'Voir',
            textColor: AppColors.textWhite,
            onPressed: () {
              // Navigate to the ongoing delivery tracking screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailsScreen(
                    delivery: _ongoingCourses.first,
                    remainingQuota: _remainingDeliveries,
                  ),
                ),
              );
            },
          ),
        ),
      );
      return; // Exit without allowing to view the new course details
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(
          delivery: delivery,
          remainingQuota: _remainingDeliveries,
        ),
      ),
    );

    // Refresh if course was accepted
    if (result == true && mounted) {
      setState(() {
        // TODO: Update with actual data from backend
        _remainingDeliveries -= 1; // Deduct quota

        // En mode normal : Supprimer la course
        if (!SimulationService().isSimulationMode) {
          _availableCourses.remove(delivery);
        } else {
          // En mode simulation : Mettre à jour le statut pour bloquer les autres
          final index = _availableCourses.indexWhere((c) => c.id == delivery.id);
          if (index != -1) {
            _availableCourses[index] = _availableCourses[index].copyWith(
              status: DeliveryStatus.accepted,
            );
          }
        }
      });
    }
  }

  // Courses en cours (accepted, pickupInProgress, pickedUp, deliveryInProgress)
  List<DeliveryModel> get _ongoingCourses {
    return _availableCourses.where((course) {
      return course.status == DeliveryStatus.accepted ||
             course.status == DeliveryStatus.pickupInProgress ||
             course.status == DeliveryStatus.pickedUp ||
             course.status == DeliveryStatus.deliveryInProgress;
    }).toList();
  }

  // Filtrage et tri des courses disponibles (pending uniquement)
  List<DeliveryModel> get _filteredAndSortedCourses {
    var courses = _availableCourses.where((course) {
      // Exclure les courses en cours
      if (course.status != DeliveryStatus.pending) {
        return false;
      }
      if (_selectedMode != null && course.mode != _selectedMode) {
        return false;
      }
      return true;
    }).toList();

    // Tri
    if (_selectedSort != null) {
      switch (_selectedSort!) {
        case CourseSortType.priceAsc:
          courses.sort((a, b) => a.price.compareTo(b.price));
          break;
        case CourseSortType.priceDesc:
          courses.sort((a, b) => b.price.compareTo(a.price));
          break;
        case CourseSortType.distance:
          // Tri par distance - simplification, distance = différence de latitude
          courses.sort((a, b) {
            final distA = (a.deliveryAddress.latitude - a.pickupAddress.latitude).abs();
            final distB = (b.deliveryAddress.latitude - b.pickupAddress.latitude).abs();
            return distA.compareTo(distB);
          });
          break;
      }
    }

    return courses;
  }

  // Vérifie si une course est nouvelle (créée il y a moins de 5 minutes)
  bool _isNewCourse(DeliveryModel delivery) {
    final now = DateTime.now();
    final difference = now.difference(delivery.createdAt);
    return difference.inMinutes < 5;
  }

  void _toggleSimulationMode() {
    setState(() {
      SimulationService().toggleSimulation();
      if (SimulationService().isSimulationMode) {
        // En mode simulation, charger les courses mockées
        _availableCourses.clear();
        _availableCourses.addAll(SimulationService().getSimulationDeliveries());
      } else {
        // En mode normal, recharger les vraies courses (TODO: API call)
        _availableCourses.clear();
        // Ici on devrait recharger depuis l'API
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          SimulationService().isSimulationMode
              ? 'Mode simulation activé - Courses mockées chargées'
              : 'Mode simulation désactivé - Courses réelles',
        ),
        backgroundColor: SimulationService().isSimulationMode
            ? AppColors.warning
            : AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.dashboard,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    AppStrings.appTagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            // Badge SIMULATION visible quand le mode est actif
            if (SimulationService().isSimulationMode) ...[
              const SizedBox(width: AppSizes.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'SIMULATION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Bouton toggle simulation
          IconButton(
            icon: Icon(
              SimulationService().isSimulationMode
                  ? Icons.science
                  : Icons.science_outlined,
              color: SimulationService().isSimulationMode
                  ? AppColors.warning
                  : AppColors.textSecondary,
            ),
            onPressed: _toggleSimulationMode,
            tooltip: SimulationService().isSimulationMode
                ? 'Désactiver la simulation'
                : 'Activer la simulation',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Course Banner (clickable)
              if (_ongoingCourses.isNotEmpty) ...[
                InkWell(
                  onTap: () {
                    // Navigate to the tracking screen of the ongoing delivery
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailsScreen(
                          delivery: _ongoingCourses.first,
                          remainingQuota: _remainingDeliveries,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingSm),
                          decoration: BoxDecoration(
                            color: AppColors.textWhite.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: const Icon(
                            Icons.directions_bike,
                            color: AppColors.textWhite,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1 course en cours',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Cliquez pour continuer',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textWhite.withValues(alpha: 0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textWhite,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
              ],

              // Quick Stats Card (nouveau)
              QuickStatsCard(
                earningsToday: _earningsToday,
                deliveriesToday: _completedToday,
                timeOnline: _timeOnline,
              ),

              const SizedBox(height: AppSizes.spacingMd),

              const Divider(),

              const SizedBox(height: AppSizes.spacingMd),

              // Daily Stats Card
              DailyStatsCard(
                completedToday: _completedToday,
                rating: _rating,
                timeOnline: _timeOnline,
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Status and Quota Card
              StatusQuotaCard(
                isOnline: _isOnline,
                remainingDeliveries: _remainingDeliveries,
                totalQuota: _totalQuota,
                onToggleOnline: _toggleOnlineStatus,
                onRechargeQuota: _rechargeQuota,
              ),

              const SizedBox(height: AppSizes.spacingLg),

              const Divider(),

              const SizedBox(height: AppSizes.spacingLg),

              // Section: Courses disponibles
              Row(
                children: [
                  Text(
                    'Courses disponibles',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Filters
              CourseFilters(
                selectedMode: _selectedMode,
                selectedSort: _selectedSort,
                onModeChanged: (mode) {
                  setState(() {
                    _selectedMode = mode;
                  });
                },
                onSortChanged: (sort) {
                  setState(() {
                    _selectedSort = sort;
                  });
                },
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Available Courses Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.availableCourses,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (_filteredAndSortedCourses.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _ongoingCourses.isNotEmpty
                            ? AppColors.warning
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_ongoingCourses.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.block,
                                size: 14,
                                color: AppColors.textWhite,
                              ),
                            ),
                          Text(
                            _ongoingCourses.isNotEmpty
                                ? '${_filteredAndSortedCourses.length} bloquées'
                                : '${_filteredAndSortedCourses.length} disponibles',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Available Courses List
              if (_isLoading)
                // Skeleton loading
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.spacingMd),
                  itemBuilder: (context, index) => const CourseSkeleton(),
                )
              else if (_filteredAndSortedCourses.isEmpty)
                EmptyState(
                  icon: Icons.delivery_dining_outlined,
                  title: _selectedMode != null || _selectedSort != null
                      ? 'Aucune course trouvée'
                      : AppStrings.noCourses,
                  message: _selectedMode != null || _selectedSort != null
                      ? 'Essayez de modifier vos filtres'
                      : (_remainingDeliveries > 0
                          ? 'Aucune course disponible pour le moment'
                          : AppStrings.rechargeQuota),
                  buttonText: _remainingDeliveries == 0 ? 'Recharger' : null,
                  onButtonPressed: _remainingDeliveries == 0 ? _rechargeQuota : null,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredAndSortedCourses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.spacingMd),
                  itemBuilder: (context, index) {
                    final delivery = _filteredAndSortedCourses[index];
                    final isBlocked = _ongoingCourses.isNotEmpty;

                    return Stack(
                      children: [
                        AvailableCourseCard(
                          delivery: delivery,
                          isNew: _isNewCourse(delivery),
                          onTap: () => _viewCourseDetails(delivery),
                        ),
                        if (isBlocked)
                          const BlockedCourseOverlay(),
                      ],
                    );
                  },
                ),

              const SizedBox(height: AppSizes.spacingXl),
            ],
          ),
        ),
      ),
      floatingActionButton: const QuickActionsFab(),
    );
  }
}
