import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../providers/create_delivery_provider.dart';
import '../../../widgets/place_search_field.dart';

/// Step 1: Sélection du point de départ
class PickupLocationStep extends ConsumerStatefulWidget {
  const PickupLocationStep({super.key});

  @override
  ConsumerState<PickupLocationStep> createState() => _PickupLocationStepState();
}

class _PickupLocationStepState extends ConsumerState<PickupLocationStep> {
  GoogleMapController? _mapController;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  LatLng _currentPosition = const LatLng(12.3686, -1.5275); // Ouagadougou par défaut

  Set<Marker> _markers = {};

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
    // Vérifier si une localisation est déjà sélectionnée dans le provider
    final state = ref.read(createDeliveryProvider);
    if (state.pickupLocation != null) {
      setState(() {
        _currentPosition = state.pickupLocation!;
        _selectedAddress = state.pickupAddress;
        _isLoadingLocation = false;
        _markers = {
          Marker(
            markerId: const MarkerId('pickup'),
            position: state.pickupLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Point de départ'),
          ),
        };
      });
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

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Point de départ'),
        ),
      };
    });

    // Animer la caméra vers la position
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );

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
        ref.read(createDeliveryProvider.notifier).setPickupLocation(
          position,
          _selectedAddress!,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isLoadingAddress = false;
        });

        // Update provider with coordinates
        ref.read(createDeliveryProvider.notifier).setPickupLocation(
          position,
          _selectedAddress!,
        );
      }
    }
  }

  void _onPlaceSelected(PlaceSearchResult result) {
    final position = result.location;

    setState(() {
      _selectedAddress = result.address;
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Point de départ', snippet: result.address),
        ),
      };
    });

    // Animer la caméra vers la position
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, AppSizes.mapDefaultZoom),
    );

    // Update provider
    ref.read(createDeliveryProvider.notifier).setPickupLocation(
      position,
      result.address,
    );
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
    return Column(
      children: [
        // Champ de recherche d'adresse
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          color: Colors.white,
          child: PlaceSearchField(
            label: 'Point de départ',
            hint: 'Rechercher une adresse...',
            iconColor: AppColors.primary,
            initialValue: _selectedAddress,
            onPlaceSelected: _onPlaceSelected,
            onTapMap: () {
              // Focus sur la carte - scroll vers le bas si nécessaire
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
                  target: _currentPosition,
                  zoom: AppSizes.mapDefaultZoom,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: _onMapTap,
                markers: _markers,
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

              // Adresse sélectionnée (si pas en chargement)
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
                    child: Row(
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
                                'Point de départ sélectionné',
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.touch_app,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingMd),
                        const Expanded(
                          child: Text(
                            'Touchez la carte pour sélectionner le point de départ',
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
                  heroTag: 'pickup_location',
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
