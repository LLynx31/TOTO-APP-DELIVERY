import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/route_names.dart';
import '../../../domain/entities/delivery.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/delivery_card.dart';

/// Écran d'accueil avec carte Google Maps
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Charger les livraisons immédiatement (prioritaire)
    _loadActiveDeliveries();
    // Charger la localisation en parallèle
    _initializeLocation();
  }

  /// Initialiser la localisation
  Future<void> _initializeLocation() async {
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (mounted && position != null) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        _moveCameraToCurrentLocation();
      } else if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Déplacer la caméra vers la position actuelle
  Future<void> _moveCameraToCurrentLocation() async {
    if (_currentPosition == null) return;

    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        AppSizes.mapDefaultZoom,
      ),
    );

    // Ajouter un marqueur pour la position actuelle
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Ma position'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });
  }

  /// Charger les livraisons actives
  Future<void> _loadActiveDeliveries() async {
    debugPrint('[HomeScreen] _loadActiveDeliveries called');
    try {
      await ref.read(deliveriesProvider.notifier).loadDeliveries();
      debugPrint('[HomeScreen] loadDeliveries completed');
    } catch (e) {
      debugPrint('[HomeScreen] loadDeliveries error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final deliveriesState = ref.watch(deliveriesProvider);

    debugPrint('[HomeScreen] build - deliveriesState: ${deliveriesState.runtimeType}');

    // Obtenir le nom de l'utilisateur
    String userName = 'Utilisateur';
    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName.split(' ').first;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Maps en plein écran
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(5.3600, -4.0083), // Abidjan par défaut
              zoom: AppSizes.mapDefaultZoom,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Header avec infos utilisateur
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(AppSizes.paddingMd),
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingMd),
                    // Nom et quota
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, $userName',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            'Bienvenue sur TOTO',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton pour recentrer sur la position actuelle
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.38,
            right: AppSizes.paddingLg,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'location_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _moveCameraToCurrentLocation,
              child: Icon(
                Icons.my_location,
                color: AppColors.primary,
              ),
            ),
          ),

          // Bouton "Nouvelle livraison" - Centré en bas au-dessus du panneau
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.12,
            left: AppSizes.paddingLg,
            right: AppSizes.paddingLg,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.goToCreateDelivery(),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingMd + 4,
                      horizontal: AppSizes.paddingLg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingMd),
                        const Text(
                          AppStrings.newDelivery,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom sheet avec livraisons actives - Swipable jusqu'en bas
          DraggableScrollableSheet(
            initialChildSize: 0.08,
            minChildSize: 0.08,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.08, 0.35, 0.6, 0.85],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusXl),
                    topRight: Radius.circular(AppSizes.radiusXl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle - Plus visible pour indiquer le swipe
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingMd),
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Titre avec compteur
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppStrings.activeDeliveries,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              if (deliveriesState is DeliveriesLoaded) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${deliveriesState.deliveries.where((d) => d.status == DeliveryStatus.pending || d.status == DeliveryStatus.accepted || d.status == DeliveryStatus.pickupInProgress || d.status == DeliveryStatus.pickedUp || d.status == DeliveryStatus.deliveryInProgress).length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              context.go(RoutePaths.deliveries);
                            },
                            child: Text(
                              AppStrings.viewAll,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingSm),
                    // Liste des livraisons
                    Expanded(
                      child: _buildDeliveriesList(deliveriesState, scrollController),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesList(DeliveriesState state, ScrollController scrollController) {
    if (state is DeliveriesLoading || state is DeliveriesInitial) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              'Chargement...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (state is DeliveriesError) {
      return SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSizes.spacingMd),
              Text(
                'Impossible de charger les livraisons',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingSm),
              Text(
                state.message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingLg),
              ElevatedButton.icon(
                onPressed: _loadActiveDeliveries,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is DeliveriesLoaded) {
      // Filtrer seulement les livraisons actives (pending, accepted, pickup_in_progress, picked_up, delivery_in_progress)
      final activeDeliveries = state.deliveries
          .where((d) =>
              d.status == DeliveryStatus.pending ||
              d.status == DeliveryStatus.accepted ||
              d.status == DeliveryStatus.pickupInProgress ||
              d.status == DeliveryStatus.pickedUp ||
              d.status == DeliveryStatus.deliveryInProgress)
          .toList();

      if (activeDeliveries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSizes.spacingMd),
              Text(
                AppStrings.noActiveDeliveries,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
        itemCount: activeDeliveries.length,
        itemBuilder: (context, index) {
          final delivery = activeDeliveries[index];
          return DeliveryCard(
            delivery: delivery,
            onTap: () {
              context.push('/delivery/${delivery.id}');
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
