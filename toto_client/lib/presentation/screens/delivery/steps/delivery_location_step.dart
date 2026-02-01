import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../providers/create_delivery_provider.dart';
import '../../../widgets/place_search_field.dart';

/// Step 2: Sélection du point d'arrivée
class DeliveryLocationStep extends ConsumerStatefulWidget {
  const DeliveryLocationStep({super.key});

  @override
  ConsumerState<DeliveryLocationStep> createState() =>
      _DeliveryLocationStepState();
}

class _DeliveryLocationStepState extends ConsumerState<DeliveryLocationStep> {
  GoogleMapController? _mapController;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  LatLng _currentPosition = const LatLng(12.3686, -1.5275); // Ouagadougou par défaut

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final state = ref.read(createDeliveryProvider);

    // Si une localisation de livraison est déjà sélectionnée
    if (state.deliveryLocation != null) {
      setState(() {
        _currentPosition = state.deliveryLocation!;
        _selectedAddress = state.deliveryAddress;
        _isLoadingLocation = false;
      });
      _updateMarkersAndRoute();
      return;
    }

    // Sinon, utiliser le point de départ comme position initiale
    if (state.pickupLocation != null) {
      setState(() {
        _currentPosition = state.pickupLocation!;
        _isLoadingLocation = false;
      });
      _updateMarkersAndRoute();
      return;
    }

    try {
      final position = await LocationHelper.getCurrentPosition();
      if (mounted && position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, AppSizes.mapDefaultZoom),
        );

        _updateMarkersAndRoute();
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
      }
    }
  }

  void _updateMarkersAndRoute() {
    final state = ref.read(createDeliveryProvider);
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Add pickup marker if available
    if (state.pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: state.pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Point de départ',
            snippet: state.pickupAddress,
          ),
        ),
      );
    }

    // Add delivery marker if available
    if (state.deliveryLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: state.deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Point d\'arrivée',
            snippet: state.deliveryAddress,
          ),
        ),
      );

      // Add route line if both locations are set
      if (state.pickupLocation != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [state.pickupLocation!, state.deliveryLocation!],
            color: AppColors.primary,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );

        // Adjust camera to show both markers
        _fitBothLocations(state.pickupLocation!, state.deliveryLocation!);
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  void _fitBothLocations(LatLng pickup, LatLng delivery) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        pickup.latitude < delivery.latitude ? pickup.latitude : delivery.latitude,
        pickup.longitude < delivery.longitude
            ? pickup.longitude
            : delivery.longitude,
      ),
      northeast: LatLng(
        pickup.latitude > delivery.latitude ? pickup.latitude : delivery.latitude,
        pickup.longitude > delivery.longitude
            ? pickup.longitude
            : delivery.longitude,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    // Get address from coordinates
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.subAdministrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address.isNotEmpty ? address : 'Adresse non trouvée';
          _isLoadingAddress = false;
        });

        // Update provider
        ref.read(createDeliveryProvider.notifier).setDeliveryLocation(
          position,
          _selectedAddress!,
        );

        // Update markers and route
        _updateMarkersAndRoute();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isLoadingAddress = false;
        });

        // Update provider with coordinates
        ref.read(createDeliveryProvider.notifier).setDeliveryLocation(
          position,
          _selectedAddress!,
        );

        // Update markers and route
        _updateMarkersAndRoute();
      }
    }
  }

  void _onPlaceSelected(PlaceSearchResult result) {
    final position = result.location;

    setState(() {
      _selectedAddress = result.address;
    });

    // Animer la caméra vers la position
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, AppSizes.mapDefaultZoom),
    );

    // Update provider
    ref.read(createDeliveryProvider.notifier).setDeliveryLocation(
      position,
      result.address,
    );

    // Update markers and route
    _updateMarkersAndRoute();
  }

  Future<void> _useCurrentLocation() async {
    if (_isLoadingLocation) return;

    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);

        // Animate camera
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, AppSizes.mapDefaultZoom),
        );

        // Select location
        await _onMapTap(latLng);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'obtenir la localisation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDeliveryProvider);

    return Column(
      children: [
        // Champ de recherche d'adresse
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          color: Colors.white,
          child: PlaceSearchField(
            label: 'Point d\'arrivée',
            hint: 'Rechercher une adresse de livraison...',
            iconColor: AppColors.error,
            initialValue: _selectedAddress,
            onPlaceSelected: _onPlaceSelected,
            onTapMap: () {
              FocusScope.of(context).unfocus();
            },
          ),
        ),

        // Carte Google Maps
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: state.pickupLocation ?? _currentPosition,
                  zoom: AppSizes.mapDefaultZoom,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Update markers after map is created
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _updateMarkersAndRoute();
                  });
                },
                onTap: _onMapTap,
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),

              // Indicateur de chargement d'adresse
              if (_isLoadingAddress)
                Positioned(
                  top: AppSizes.spacingMd,
                  left: AppSizes.spacingMd,
                  right: AppSizes.spacingMd,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSizes.spacingMd),
                        Text(
                          'Recherche de l\'adresse...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Adresse sélectionnée + distance/prix
              if (_selectedAddress != null && !_isLoadingAddress)
                Positioned(
                  top: AppSizes.spacingMd,
                  left: AppSizes.spacingMd,
                  right: AppSizes.spacingMd,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSizes.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Point d\'arrivée sélectionné',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedAddress!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Distance et prix estimé
                        if (state.distanceKm != null &&
                            state.estimatedPrice != null) ...[
                          const SizedBox(height: AppSizes.spacingMd),
                          Container(
                            padding: const EdgeInsets.all(AppSizes.spacingSm),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.straighten,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${state.distanceKm!.toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payments,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${state.estimatedPrice!.toStringAsFixed(0)} FCFA',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Hint pour toucher la carte
              if (_selectedAddress == null && !_isLoadingAddress)
                Positioned(
                  top: AppSizes.spacingMd,
                  left: AppSizes.spacingMd,
                  right: AppSizes.spacingMd,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.touch_app,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingMd),
                        const Expanded(
                          child: Text(
                            'Touchez la carte pour sélectionner le point d\'arrivée',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bouton "Ma position"
              Positioned(
                bottom: AppSizes.spacingMd,
                right: AppSizes.spacingMd,
                child: FloatingActionButton(
                  heroTag: 'delivery_location',
                  onPressed: _useCurrentLocation,
                  backgroundColor: Colors.white,
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
