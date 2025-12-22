import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../providers/create_delivery_provider.dart';

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
  LatLng _currentPosition = const LatLng(5.3600, -4.0083); // Abidjan par défaut

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
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (mounted && position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, AppSizes.mapDefaultZoom),
        );
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
    return Stack(
      children: [
        // Google Map
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

        // Instructions overlay
        Positioned(
          top: AppSizes.spacingMd,
          left: AppSizes.spacingMd,
          right: AppSizes.spacingMd,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacingMd),
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
                      padding: const EdgeInsets.all(AppSizes.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingSm),
                    const Expanded(
                      child: Text(
                        'Sélectionnez le point de départ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedAddress != null) ...[
                  const SizedBox(height: AppSizes.spacingSm),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingSm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: AppSizes.spacingXs),
                        Expanded(
                          child: _isLoadingAddress
                              ? const Text(
                                  'Chargement de l\'adresse...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : Text(
                                  _selectedAddress!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // "Use current location" button
        Positioned(
          bottom: AppSizes.spacingMd,
          right: AppSizes.spacingMd,
          child: FloatingActionButton(
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
                : const Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                  ),
          ),
        ),
      ],
    );
  }
}
