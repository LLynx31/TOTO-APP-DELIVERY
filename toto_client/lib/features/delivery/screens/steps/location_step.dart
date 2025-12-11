import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

class LocationStep extends StatefulWidget {
  final AddressModel? initialPickup;
  final AddressModel? initialDelivery;
  final Function({
    required AddressModel pickup,
    required AddressModel delivery,
  }) onCompleted;

  const LocationStep({
    super.key,
    this.initialPickup,
    this.initialDelivery,
    required this.onCompleted,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(5.3600, -4.0083); // Abidjan par défaut
  final Set<Marker> _markers = {};
  LatLng? _pickupLocation;
  LatLng? _deliveryLocation;
  bool _isSelectingPickup = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPickup != null) {
      _pickupController.text = widget.initialPickup!.address;
      _pickupLocation = LatLng(
        widget.initialPickup!.latitude,
        widget.initialPickup!.longitude,
      );
    }
    if (widget.initialDelivery != null) {
      _deliveryController.text = widget.initialDelivery!.address;
      _deliveryLocation = LatLng(
        widget.initialDelivery!.latitude,
        widget.initialDelivery!.longitude,
      );
    }
    _updateMarkers();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPosition),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Point de collecte'),
        ),
      );
    }

    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Point de livraison'),
        ),
      );
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    try {
      // Reverse geocoding to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street}, ${place.locality}, ${place.country}';

        setState(() {
          if (_isSelectingPickup) {
            _pickupLocation = position;
            _pickupController.text = address;
          } else {
            _deliveryLocation = position;
            _deliveryController.text = address;
          }
          _updateMarkers();
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Use selected coordinates from map or default to current position
      final pickup = AddressModel(
        address: _pickupController.text,
        latitude: _pickupLocation?.latitude ?? _currentPosition.latitude,
        longitude: _pickupLocation?.longitude ?? _currentPosition.longitude,
      );

      final delivery = AddressModel(
        address: _deliveryController.text,
        latitude: _deliveryLocation?.latitude ?? _currentPosition.latitude,
        longitude: _deliveryLocation?.longitude ?? _currentPosition.longitude,
      );

      widget.onCompleted(pickup: pickup, delivery: delivery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Google Map
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                // Mode selector (Pickup/Delivery)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSelectingPickup = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isSelectingPickup
                                    ? AppColors.secondary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Text(
                                'Point A (Collecte)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isSelectingPickup
                                      ? AppColors.textWhite
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSelectingPickup = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isSelectingPickup
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Text(
                                'Point B (Livraison)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isSelectingPickup
                                      ? AppColors.textWhite
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // My location button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: AppColors.background,
                    onPressed: _getCurrentLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Point A (départ)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Pickup Address
                  CustomTextField(
                    controller: _pickupController,
                    hint: AppStrings.enterPickupAddress,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  Text(
                    'Point B (arrivée)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Delivery Address
                  CustomTextField(
                    controller: _deliveryController,
                    hint: AppStrings.enterDeliveryAddress,
                    prefixIcon: const Icon(Icons.flag_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Use My Location Button
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Get current location
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text(AppStrings.useMyLocation),
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  // Next Button
                  CustomButton(
                    text: AppStrings.next,
                    onPressed: _handleNext,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
