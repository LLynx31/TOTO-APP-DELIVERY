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
    _initializeLocation();
    _loadActiveDeliveries();
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
    await ref.read(deliveriesProvider.notifier).loadDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final deliveriesState = ref.watch(deliveriesProvider);

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

          // Bouton "Nouvelle livraison" - Amélioré UI
          Positioned(
            bottom: 200,
            right: AppSizes.paddingMd,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () {
                  // Navigation vers la création de livraison
                  context.goToCreateDelivery();
                },
                backgroundColor: AppColors.primary,
                elevation: 0,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                label: const Text(
                  AppStrings.newDelivery,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // Bouton pour recentrer sur la position actuelle
          Positioned(
            bottom: 280,
            right: AppSizes.paddingMd,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _moveCameraToCurrentLocation,
              child: Icon(
                Icons.my_location,
                color: AppColors.primary,
              ),
            ),
          ),

          // Bottom sheet avec livraisons actives
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.6,
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: AppSizes.spacingMd),
                      width: AppSizes.bottomSheetHandleWidth,
                      height: AppSizes.bottomSheetHandleHeight,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                    // Titre
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.activeDeliveries,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigation vers l'onglet livraisons
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
    if (state is DeliveriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is DeliveriesError) {
      return Center(
        child: Text(
          state.message,
          style: TextStyle(color: AppColors.error),
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
