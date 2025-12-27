import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/hybrid_delivery_service.dart';
import '../../core/services/simulation_service.dart';
import '../../core/utils/delivery_utils.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/utils/loading_overlay.dart';
import '../../core/utils/error_messages.dart';
import '../../shared/models/delivery_model.dart';
import '../../shared/widgets/widgets.dart';
import '../scanner/qr_scanner_screen.dart';
import 'widgets/delivery_timeline_widget.dart';
import 'widgets/package_info_card.dart';
import 'widgets/eta_distance_widget.dart';
import 'widgets/navigation_button.dart';
import 'widgets/delivery_mode_badge.dart';
import 'widgets/enhanced_problem_reporter.dart';
import 'delivery_success_screen.dart';

class TrackingScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const TrackingScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final _hybridDeliveryService = HybridDeliveryService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  DeliveryStatus _currentStatus = DeliveryStatus.accepted;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;

  // Distance calculated from GPS coordinates
  double _distanceKm = 0.0;

  // Travel timer for simulation
  Timer? _travelTimer;
  int _remainingTravelSeconds = 0;
  bool _isTraveling = false;

  // Sheet state
  bool _isSheetExpanded = true;
  static const double _minSheetSize = 0.15;
  static const double _maxSheetSize = 0.6;

  /// Get customer/receiver phone number from delivery data
  String get _customerPhone {
    // For deliverer: use delivery_phone (receiver phone at destination)
    // The phone is stored in deliveryAddress for the destination
    return widget.delivery.deliveryAddress.phone ??
           widget.delivery.pickupAddress.phone ??
           'Non disponible';
  }

  /// Get receiver name from delivery data
  String? get _receiverName {
    return widget.delivery.deliveryAddress.contactName;
  }

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _travelTimer?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    if (_isSheetExpanded) {
      _sheetController.animateTo(
        _minSheetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _sheetController.animateTo(
        _maxSheetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    setState(() {
      _isSheetExpanded = !_isSheetExpanded;
    });
  }

  /// Calculate distance between two GPS coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180);

  void _initializeTracking() {
    setState(() {
      _currentStatus = widget.delivery.status;
      // Mock current location (in reality, this would come from GPS)
      _currentLocation = LatLng(
        widget.delivery.pickupAddress.latitude,
        widget.delivery.pickupAddress.longitude,
      );
    });
    _updateMapMarkers();

    // Démarrer automatiquement la course si elle est en pending ou accepted
    if (_currentStatus == DeliveryStatus.pending || _currentStatus == DeliveryStatus.accepted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Passer directement à "En route vers le point A"
          _updateStatus(DeliveryStatus.pickupInProgress);
        }
      });
    }
  }

  void _updateMapMarkers() {
    setState(() {
      // Déterminer la destination actuelle
      final bool isGoingToPickup = _currentStatus == DeliveryStatus.accepted ||
          _currentStatus == DeliveryStatus.pickupInProgress;

      _markers = {
        // Marqueur position du livreur (bleu cyan)
        if (_currentLocation != null)
          Marker(
            markerId: const MarkerId('deliverer_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueCyan),
            infoWindow: const InfoWindow(
              title: '🛵 Ma position',
              snippet: 'Livreur',
            ),
            zIndexInt: 3, // Au-dessus des autres marqueurs
          ),

        // Point A - Collecte (orange) - toujours visible sauf après livraison
        if (_currentStatus != DeliveryStatus.delivered)
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(
              widget.delivery.pickupAddress.latitude,
              widget.delivery.pickupAddress.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                isGoingToPickup ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: isGoingToPickup ? '📍 Point A - Destination' : '✅ Point A - Collecté',
              snippet: widget.delivery.pickupAddress.address,
            ),
            zIndexInt: isGoingToPickup ? 2 : 1,
          ),

        // Point B - Livraison (rouge) - toujours visible
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(
            widget.delivery.deliveryAddress.latitude,
            widget.delivery.deliveryAddress.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              !isGoingToPickup ? BitmapDescriptor.hueRed : BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(
            title: !isGoingToPickup ? '📍 Point B - Destination' : '🏁 Point B - Livraison',
            snippet: widget.delivery.deliveryAddress.address,
          ),
          zIndexInt: !isGoingToPickup ? 2 : 1,
        ),
      };

      // Coordonnées des points
      final pickupLatLng = LatLng(
        widget.delivery.pickupAddress.latitude,
        widget.delivery.pickupAddress.longitude,
      );
      final deliveryLatLng = LatLng(
        widget.delivery.deliveryAddress.latitude,
        widget.delivery.deliveryAddress.longitude,
      );

      // Create polylines
      _polylines = {
        // Ligne entre Point A et Point B (toujours visible, gris pointillé)
        Polyline(
          polylineId: const PolylineId('route_a_to_b'),
          points: [pickupLatLng, deliveryLatLng],
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          width: 3,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ),

        // Ligne entre livreur et sa destination actuelle (couleur primaire)
        if (_currentLocation != null)
          Polyline(
            polylineId: const PolylineId('route_to_destination'),
            points: [
              _currentLocation!,
              isGoingToPickup ? pickupLatLng : deliveryLatLng,
            ],
            color: AppColors.primary,
            width: 5,
          ),
      };

      // Calculate real distance based on status and current location
      if (_currentLocation != null) {
        if (_currentStatus == DeliveryStatus.accepted ||
            _currentStatus == DeliveryStatus.pickupInProgress) {
          // Distance to pickup point
          _distanceKm = _calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            widget.delivery.pickupAddress.latitude,
            widget.delivery.pickupAddress.longitude,
          );
        } else if (_currentStatus == DeliveryStatus.pickedUp ||
                   _currentStatus == DeliveryStatus.deliveryInProgress) {
          // Distance to delivery point
          _distanceKm = _calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            widget.delivery.deliveryAddress.latitude,
            widget.delivery.deliveryAddress.longitude,
          );
        } else {
          _distanceKm = 0.0;
        }
      }
    });
  }

  /// Recentrer la carte sur la position du livreur
  Future<void> _centerOnMyLocation() async {
    if (_currentLocation == null) return;

    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation!,
          zoom: 16,
        ),
      ),
    );
  }

  // Start travel timer for simulation mode
  void _startTravelTimer({required int seconds, required VoidCallback onComplete}) {
    // Cancel any existing timer
    _travelTimer?.cancel();

    setState(() {
      _isTraveling = true;
      _remainingTravelSeconds = seconds;
    });

    _travelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingTravelSeconds--;
      });

      if (_remainingTravelSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isTraveling = false;
        });
        onComplete();
      }
    });
  }

  void _updateStatus(DeliveryStatus newStatus) async {
    try {
      print('🔄 TrackingScreen: Mise à jour du statut vers ${newStatus.displayName}...');

      // Note: Status updates are handled by specific methods (startPickup, confirmPickup, etc.)
      // This method is mainly for UI updates after API calls

      if (!mounted) return;

      setState(() {
        _currentStatus = newStatus;
      });

      _updateMapMarkers();

      // Show success message for intermediate transitions
      if (newStatus != DeliveryStatus.delivered &&
          newStatus != DeliveryStatus.pickupInProgress &&
          newStatus != DeliveryStatus.deliveryInProgress) {
        ToastUtils.showSuccess(
          context,
          '${AppStrings.newStatus} ${newStatus.displayName}',
          title: 'Statut mis à jour',
        );
      }

      // Automatic transitions
      // After acceptance → AUTO transition to pickupInProgress
      if (newStatus == DeliveryStatus.accepted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _currentStatus == DeliveryStatus.accepted) {
            _updateStatus(DeliveryStatus.pickupInProgress);
          }
        });
      }

      // After pickupInProgress → Start travel timer in simulation mode (45s)
      if (newStatus == DeliveryStatus.pickupInProgress && SimulationService().isSimulationMode) {
        _startTravelTimer(
          seconds: 45,
          onComplete: () {
            // Timer finished - scan button will appear
          },
        );
      }

      // After pickup → AUTO transition to deliveryInProgress
      if (newStatus == DeliveryStatus.pickedUp) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _currentStatus == DeliveryStatus.pickedUp) {
            _updateStatus(DeliveryStatus.deliveryInProgress);
          }
        });
      }

      // After deliveryInProgress → Start travel timer in simulation mode (30s)
      if (newStatus == DeliveryStatus.deliveryInProgress && SimulationService().isSimulationMode) {
        _startTravelTimer(
          seconds: 30,
          onComplete: () {
            // Timer finished - scan button will appear
          },
        );
      }

      // After delivery → Navigate to Success Screen
      if (newStatus == DeliveryStatus.delivered) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliverySuccessScreen(delivery: widget.delivery),
          ),
        );
      }
    } catch (e) {
      print('❌ TrackingScreen: Erreur lors de la mise à jour du statut: $e');
      if (!mounted) return;

      ToastUtils.showError(
        context,
        ErrorMessages.deliveryError(e),
        title: 'Erreur de mise à jour',
      );
    }
  }


  void _reportProblem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedProblemReporter(
          deliveryId: widget.delivery.id,
        ),
      ),
    );
  }

  Future<void> _callCustomer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: _customerPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ToastUtils.showError(
        context,
        'Impossible d\'appeler le numéro $_customerPhone',
        title: 'Erreur d\'appel',
      );
    }
  }

  // Scanner QR au point A (pickup) - Utilise HybridDeliveryService
  Future<void> _handleScanPickup() async {
    LoadingOverlay.show(context, message: 'Scan en cours...');

    try {
      print('📦 TrackingScreen: Scan QR pickup pour ${widget.delivery.id}...');

      // En mode simulation, utiliser le QR code simulé
      final qrCode = _hybridDeliveryService.isSimulationMode
          ? 'SIMULATION-PICKUP-${widget.delivery.id}'
          : 'REAL-QR-CODE'; // Ce sera remplacé par le vrai scan

      final updatedDelivery = await _hybridDeliveryService.confirmPickup(
        widget.delivery.id,
        qrCode,
      );

      // Always hide loading overlay first
      await LoadingOverlay.hide();

      if (!mounted) return;

      print('✅ TrackingScreen: Pickup confirmé!');
      _showSuccessDialog(
        title: 'Colis récupéré !',
        message: 'Le QR code a été scanné avec succès au point A.',
      );
      _updateStatus(updatedDelivery.status);
    } catch (e) {
      print('❌ TrackingScreen: Erreur lors du scan pickup: $e');

      // Always hide loading overlay first
      await LoadingOverlay.hide();

      if (!mounted) return;

      ToastUtils.showError(
        context,
        ErrorMessages.fromException(e),
        title: 'Échec du scan',
      );
    }
  }

  // Scanner QR au point B (delivery) - Utilise HybridDeliveryService
  Future<void> _handleScanDelivery() async {
    LoadingOverlay.show(context, message: 'Scan en cours...');

    try {
      print('📦 TrackingScreen: Scan QR delivery pour ${widget.delivery.id}...');

      // En mode simulation, utiliser le QR code simulé
      final qrCode = _hybridDeliveryService.isSimulationMode
          ? 'SIMULATION-DELIVERY-${widget.delivery.id}'
          : 'REAL-QR-CODE'; // Ce sera remplacé par le vrai scan

      final updatedDelivery = await _hybridDeliveryService.confirmDelivery(
        widget.delivery.id,
        qrCode,
      );

      if (!mounted) return;

      print('✅ TrackingScreen: Delivery confirmée!');

      // Always hide loading overlay first
      await LoadingOverlay.hide();

      if (!mounted) return;

      _showSuccessDialog(
        title: 'Livraison effectuée !',
        message: 'Le QR code a été scanné avec succès au point B.',
      );
      _updateStatus(updatedDelivery.status);
    } catch (e) {
      print('❌ TrackingScreen: Erreur lors du scan delivery: $e');

      // Always hide loading overlay first
      await LoadingOverlay.hide();

      if (!mounted) return;

      ToastUtils.showError(
        context,
        ErrorMessages.fromException(e),
        title: 'Échec du scan',
      );
    }
  }

  void _showSuccessDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: AppSizes.spacingSm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ??
                  LatLng(
                    widget.delivery.pickupAddress.latitude,
                    widget.delivery.pickupAddress.longitude,
                  ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              elevation: 4,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSm),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          // Info badge - Course en cours
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pending_actions,
                      color: AppColors.textWhite,
                      size: 18,
                    ),
                    const SizedBox(width: AppSizes.spacingXs),
                    Text(
                      'Course en cours',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Info Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          DeliveryUtils.formatDeliveryIdWithPrefix(widget.delivery.id),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Row(
                        children: [
                          DeliveryModeBadge(mode: widget.delivery.mode),
                          const SizedBox(width: AppSizes.spacingSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingSm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.courseInProgress.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              _currentStatus.displayName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.courseInProgress,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingSm),

                  // NEW: ETA & Distance Widget
                  ETADistanceWidget(
                    status: _currentStatus,
                    distanceKm: _distanceKm,
                  ),
                  const SizedBox(height: AppSizes.spacingSm),

                  Row(
                    children: [
                      Icon(
                        _currentStatus == DeliveryStatus.accepted ||
                                _currentStatus == DeliveryStatus.pickupInProgress
                            ? Icons.trip_origin
                            : Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Expanded(
                        child: Text(
                          _currentStatus == DeliveryStatus.accepted ||
                                  _currentStatus == DeliveryStatus.pickupInProgress
                              ? widget.delivery.pickupAddress.address
                              : widget.delivery.deliveryAddress.address,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bouton recentrer sur ma position
          Positioned(
            bottom: MediaQuery.of(context).size.height * _maxSheetSize + 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'center_location',
              onPressed: _centerOnMyLocation,
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.primary,
              elevation: 4,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom Actions Card - Draggable Sheet
          DraggableScrollableSheet(
            initialChildSize: _maxSheetSize,
            minChildSize: _minSheetSize,
            maxChildSize: _maxSheetSize,
            controller: _sheetController,
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _isSheetExpanded = notification.extent > (_minSheetSize + _maxSheetSize) / 2;
                  });
                  return true;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusLg),
                      topRight: Radius.circular(AppSizes.radiusLg),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle + Toggle button
                      GestureDetector(
                        onTap: _toggleSheet,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
                          child: Column(
                            children: [
                              // Drag handle
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacingSm),
                              // Toggle indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isSheetExpanded
                                        ? Icons.keyboard_arrow_down
                                        : Icons.keyboard_arrow_up,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isSheetExpanded ? 'Réduire' : 'Afficher les détails',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Scrollable content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            left: AppSizes.paddingMd,
                            right: AppSizes.paddingMd,
                            bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingMd,
                          ),
                          children: [
                            // Package Info Card
                            PackageInfoCard(
                              package: widget.delivery.package,
                              price: widget.delivery.price,
                            ),
                            const SizedBox(height: AppSizes.spacingMd),

                            // Delivery Timeline Widget
                            DeliveryTimelineWidget(
                              currentStatus: _currentStatus,
                              createdAt: widget.delivery.createdAt,
                              acceptedAt: widget.delivery.acceptedAt,
                              pickedUpAt: widget.delivery.pickedUpAt,
                              deliveredAt: widget.delivery.deliveredAt,
                            ),
                            const SizedBox(height: AppSizes.spacingLg),

                            // Navigation Button
                            if (_currentStatus != DeliveryStatus.delivered)
                              NavigationButton(
                                latitude: _currentStatus == DeliveryStatus.accepted ||
                                        _currentStatus == DeliveryStatus.pickupInProgress
                                    ? widget.delivery.pickupAddress.latitude
                                    : widget.delivery.deliveryAddress.latitude,
                                longitude: _currentStatus == DeliveryStatus.accepted ||
                                        _currentStatus == DeliveryStatus.pickupInProgress
                                    ? widget.delivery.pickupAddress.longitude
                                    : widget.delivery.deliveryAddress.longitude,
                                destinationLabel: _currentStatus == DeliveryStatus.accepted ||
                                        _currentStatus == DeliveryStatus.pickupInProgress
                                    ? 'Point A'
                                    : 'Point B',
                              ),
                            if (_currentStatus != DeliveryStatus.delivered)
                              const SizedBox(height: AppSizes.spacingMd),

                            // Call Customer Button
                            OutlinedButton.icon(
                              onPressed: _callCustomer,
                              icon: const Icon(Icons.phone, size: 20),
                              label: const Text(AppStrings.callCustomer),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacingMd),

                            // Status progression buttons
                            _buildStatusActions(),

                            const SizedBox(height: AppSizes.spacingMd),

                            // Report problem button
                            OutlinedButton.icon(
                              onPressed: _reportProblem,
                              icon: const Icon(Icons.report_problem_outlined),
                              label: const Text(AppStrings.reportProblem),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    switch (_currentStatus) {
      case DeliveryStatus.accepted:
        // Transition automatique vers pickupInProgress - ne devrait pas s'afficher longtemps
        return const SizedBox.shrink();

      case DeliveryStatus.pickupInProgress:
        // En mode simulation
        if (SimulationService().isSimulationMode) {
          // Pendant le trajet : Afficher le compte à rebours
          if (_isTraveling) {
            final minutes = _remainingTravelSeconds ~/ 60;
            final seconds = _remainingTravelSeconds % 60;
            final progress = 1 - (_remainingTravelSeconds / 45);

            return Container(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bike, color: AppColors.primary, size: 28),
                      const SizedBox(width: AppSizes.spacingMd),
                      Text(
                        'En route vers le point A...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        'Arrivée dans ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ],
              ),
            );
          }

          // Après le trajet : Afficher le bouton de scan
          return ElevatedButton.icon(
            onPressed: _handleScanPickup,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(_hybridDeliveryService.isSimulationMode
                ? 'Simuler scan Point A'
                : 'Scanner QR Point A'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          );
        }

        // En mode normal, afficher le bouton de scan QR réel
        return CustomButton(
          text: 'Arrivé au point A - Scanner QR',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRScannerScreen(
                  mode: ScannerMode.pickup,
                  deliveryId: widget.delivery.id,
                ),
              ),
            );

            if (result == true) {
              _updateStatus(DeliveryStatus.pickedUp);
            }
          },
          icon: const Icon(Icons.qr_code_scanner, size: 20),
        );

      case DeliveryStatus.pickedUp:
        // Automatic transition to deliveryInProgress - no manual button needed
        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppSizes.spacingSm),
              Expanded(
                child: Text(
                  'En route vers le point B...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        );

      case DeliveryStatus.deliveryInProgress:
        // En mode simulation
        if (SimulationService().isSimulationMode) {
          // Pendant le trajet : Afficher le compte à rebours
          if (_isTraveling) {
            final minutes = _remainingTravelSeconds ~/ 60;
            final seconds = _remainingTravelSeconds % 60;
            final progress = 1 - (_remainingTravelSeconds / 30);

            return Container(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping, color: AppColors.primary, size: 28),
                      const SizedBox(width: AppSizes.spacingMd),
                      Text(
                        'En route vers le point B...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        'Arrivée dans ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ],
              ),
            );
          }

          // Après le trajet : Afficher le bouton de scan
          return ElevatedButton.icon(
            onPressed: _handleScanDelivery,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(_hybridDeliveryService.isSimulationMode
                ? 'Simuler scan Point B'
                : 'Scanner QR Point B'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          );
        }

        // En mode normal, afficher le bouton de scan QR réel
        return CustomButton(
          text: 'Arrivé au point B - Scanner QR',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRScannerScreen(
                  mode: ScannerMode.delivery,
                  deliveryId: widget.delivery.id,
                ),
              ),
            );

            if (result == true) {
              _updateStatus(DeliveryStatus.delivered);
            }
          },
          icon: const Icon(Icons.qr_code_scanner, size: 20),
        );

      case DeliveryStatus.delivered:
        // This case should not be reached since we navigate to success screen
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
