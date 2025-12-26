import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/hybrid_delivery_service.dart';
import '../../core/services/simulation_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/utils/error_messages.dart';
import '../../shared/models/delivery_model.dart';
import '../../shared/models/deliverer_model.dart';
import '../../shared/widgets/widgets.dart';
import '../quota/quota_recharge_screen.dart';
import '../quota/providers/quota_provider.dart';
import '../profile/providers/deliverer_provider.dart';
import 'course_details_screen.dart';
import 'widgets/available_course_card.dart';
import 'widgets/status_quota_card.dart';
import 'widgets/daily_stats_card.dart';
import 'widgets/course_filters.dart';
import 'widgets/course_skeleton.dart';
import 'widgets/blocked_course_overlay.dart';
import 'widgets/quick_stats_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _hybridDeliveryService = HybridDeliveryService();

  bool _isOnline = false;
  bool _isLoading = false;

  // Stats du jour - Chargées depuis le profil du livreur
  int _completedToday = 0;
  double _earningsToday = 0; // Gains du jour en FCFA
  double _rating = 0.0;
  Duration _timeOnline = Duration.zero;

  // Filtres
  DeliveryMode? _selectedMode;
  CourseSortType? _selectedSort;

  // Livraisons disponibles - Chargées depuis l'API
  List<DeliveryModel> _availableCourses = [];

  @override
  void initState() {
    super.initState();
    // Différer les appels aux providers après la construction du widget tree
    Future(() {
      _loadAvailableDeliveries();
      _loadDelivererProfile();
      _loadQuotaData();
    });
  }

  /// Charge les données de quota depuis le backend
  Future<void> _loadQuotaData() async {
    try {
      await ref.read(quotaProvider.notifier).loadActiveQuota();
    } catch (e) {
      // Non-blocking, on continue avec les valeurs par défaut
    }
  }

  /// Getters pour accéder aux données de quota depuis le provider
  int get _remainingDeliveries => ref.watch(quotaProvider).remainingDeliveries;
  int get _totalQuota => ref.watch(quotaProvider).activeQuota?.totalPurchased ?? 0;
  bool get _hasActiveQuota => ref.watch(quotaProvider).activeQuota != null;

  /// Getter pour le deliverer et son statut de validation
  DelivererModel? get _deliverer => ref.watch(delivererProvider).deliverer;
  bool get _isAccountValidated => _deliverer?.kycStatus == KycStatus.approved;
  bool get _canAcceptDeliveries => _isAccountValidated && _remainingDeliveries > 0;

  Future<void> _loadDelivererProfile() async {
    try {
      // Charger le profil du livreur via le provider
      await ref.read(delivererProvider.notifier).loadProfile();
      // Charger les stats journalières
      await ref.read(delivererProvider.notifier).loadDailyStats();

      if (!mounted) return;

      final delivererState = ref.read(delivererProvider);
      if (delivererState.deliverer != null) {
        setState(() {
          _isOnline = delivererState.deliverer!.isOnline;
          _rating = delivererState.deliverer!.rating;
        });
      }

      // Mettre à jour les stats journalières si disponibles
      if (delivererState.dailyStats != null) {
        setState(() {
          _completedToday = delivererState.dailyStats!.completedToday;
          _earningsToday = delivererState.dailyStats!.earningsToday;
        });
      }
    } catch (e) {
      print('⚠️ DashboardScreen: Erreur chargement profil: $e');
      // Non-blocking, on continue avec les valeurs par défaut
    }
  }

  Future<void> _loadAvailableDeliveries() async {
    setState(() => _isLoading = true);

    try {
      print('📦 DashboardScreen: Chargement des livraisons disponibles...');

      final deliveries = await _hybridDeliveryService.getAvailableDeliveries();

      if (!mounted) return;

      setState(() {
        _availableCourses = deliveries;
        _isLoading = false;
      });

      print('✅ DashboardScreen: ${deliveries.length} livraisons chargées');
    } catch (e) {
      print('❌ DashboardScreen: Erreur lors du chargement: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);

      ToastUtils.showError(
        context,
        ErrorMessages.fromException(e),
        title: 'Erreur de chargement',
      );
    }
  }

  void _toggleOnlineStatus() async {
    // Vérifier d'abord si le compte est validé
    if (!_isAccountValidated) {
      ToastUtils.showWarning(
        context,
        'Votre compte doit être validé par un administrateur avant de pouvoir passer en ligne',
        title: 'Compte en attente',
      );
      return;
    }

    if (_remainingDeliveries > 0) {
      final newStatus = !_isOnline;

      try {
        // Appeler le backend pour mettre à jour la disponibilité
        final actualStatus = await ref.read(delivererProvider.notifier)
            .updateAvailability(newStatus);

        if (!mounted) return;

        setState(() {
          _isOnline = actualStatus;
        });

        if (actualStatus) {
          ToastUtils.showSuccess(
            context,
            'Vous êtes maintenant en ligne',
            title: 'En ligne',
          );
        } else {
          ToastUtils.showInfo(
            context,
            'Vous êtes maintenant hors ligne',
            title: 'Hors ligne',
          );
        }
      } catch (e) {
        ToastUtils.showError(
          context,
          'Erreur lors du changement de statut',
          title: 'Erreur',
        );
      }
    } else {
      ToastUtils.showWarning(
        context,
        'Rechargez votre quota pour passer en ligne',
        title: 'Quota insuffisant',
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
      // Recharger les données de quota depuis le backend
      await _loadQuotaData();
    }
  }

  void _viewCourseDetails(DeliveryModel delivery) async {
    // Block acceptance of new courses if there's already an ongoing delivery
    if (_ongoingCourses.isNotEmpty) {
      ToastUtils.showWarning(
        context,
        'Vous avez déjà une course en cours. Terminez-la avant d\'en accepter une nouvelle.',
        title: 'Course en cours',
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
      // Recharger les données de quota et les livraisons depuis l'API
      await _loadQuotaData();
      await _loadAvailableDeliveries();
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

  void _toggleSimulationMode() async {
    SimulationService().toggleSimulation();

    if (SimulationService().isSimulationMode) {
      ToastUtils.showWarning(
        context,
        'Rechargement des données...',
        title: 'Mode simulation activé',
      );
    } else {
      ToastUtils.showSuccess(
        context,
        'Rechargement des données...',
        title: 'Mode simulation désactivé',
      );
    }

    // Recharger les livraisons depuis l'API (simulation ou réelle)
    await _loadAvailableDeliveries();
  }

  /// Bannière affichant le statut de validation du compte
  Widget _buildValidationBanner() {
    final kycStatus = _deliverer?.kycStatus ?? KycStatus.pending;

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    switch (kycStatus) {
      case KycStatus.pending:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        borderColor = AppColors.warning.withValues(alpha: 0.3);
        textColor = AppColors.warning;
        icon = Icons.hourglass_empty;
        break;
      case KycStatus.approved:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        borderColor = AppColors.success.withValues(alpha: 0.3);
        textColor = AppColors.success;
        icon = Icons.verified;
        break;
      case KycStatus.rejected:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error.withValues(alpha: 0.3);
        textColor = AppColors.error;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kycStatus.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  kycStatus == KycStatus.pending
                      ? 'Vous ne pouvez pas encore accepter de courses'
                      : kycStatus.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
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
        onRefresh: _loadAvailableDeliveries,
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

              // Validation Status Banner (si compte non validé)
              if (_deliverer != null && !_isAccountValidated)
                _buildValidationBanner(),

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
                hasActiveQuota: _hasActiveQuota,
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
    );
  }
}
