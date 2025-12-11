import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/simulation_service.dart';
import '../../core/utils/delivery_utils.dart';
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
  DeliveryStatus _currentStatus = DeliveryStatus.accepted;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  bool _isLoading = false;

  // Mock data - TODO: Replace with API calls
  final String _customerPhone = '+225 07 12 34 56 78';
  double _mockDistance = 2.5; // km

  // Travel timer for simulation
  Timer? _travelTimer;
  int _remainingTravelSeconds = 0;
  bool _isTraveling = false;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _travelTimer?.cancel();
    super.dispose();
  }

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

    // Si la course est encore en pending, l'accepter automatiquement
    if (_currentStatus == DeliveryStatus.pending) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _updateStatus(DeliveryStatus.accepted);
        }
      });
    }
  }

  void _updateMapMarkers() {
    setState(() {
      _markers = {
        // Current location marker
        if (_currentLocation != null)
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(
              title: 'Ma position',
            ),
          ),

        // Pickup marker
        if (_currentStatus == DeliveryStatus.accepted ||
            _currentStatus == DeliveryStatus.pickupInProgress)
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(
              widget.delivery.pickupAddress.latitude,
              widget.delivery.pickupAddress.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: 'Point A - Collecte',
              snippet: widget.delivery.pickupAddress.address,
            ),
          ),

        // Delivery marker
        if (_currentStatus == DeliveryStatus.pickedUp ||
            _currentStatus == DeliveryStatus.deliveryInProgress)
          Marker(
            markerId: const MarkerId('delivery'),
            position: LatLng(
              widget.delivery.deliveryAddress.latitude,
              widget.delivery.deliveryAddress.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Point B - Livraison',
              snippet: widget.delivery.deliveryAddress.address,
            ),
          ),
      };

      // Create polyline to destination
      if (_currentLocation != null) {
        LatLng destination;
        if (_currentStatus == DeliveryStatus.accepted ||
            _currentStatus == DeliveryStatus.pickupInProgress) {
          destination = LatLng(
            widget.delivery.pickupAddress.latitude,
            widget.delivery.pickupAddress.longitude,
          );
        } else {
          destination = LatLng(
            widget.delivery.deliveryAddress.latitude,
            widget.delivery.deliveryAddress.longitude,
          );
        }

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_currentLocation!, destination],
            color: AppColors.primary,
            width: 4,
          ),
        };
      }

      // Update mock distance based on status
      if (_currentStatus == DeliveryStatus.accepted ||
          _currentStatus == DeliveryStatus.pickupInProgress) {
        _mockDistance = 2.5;
      } else if (_currentStatus == DeliveryStatus.pickedUp ||
                 _currentStatus == DeliveryStatus.deliveryInProgress) {
        _mockDistance = 3.8;
      } else {
        _mockDistance = 0.0;
      }
    });
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
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _currentStatus = newStatus;
      _isLoading = false;
    });

    _updateMapMarkers();

    // Show success message for intermediate transitions
    if (newStatus != DeliveryStatus.delivered &&
        newStatus != DeliveryStatus.pickupInProgress &&
        newStatus != DeliveryStatus.deliveryInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.newStatus} ${newStatus.displayName}'),
          backgroundColor: AppColors.success,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'appeler le numéro $_customerPhone'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Simulation: Scanner QR au point A (pickup)
  Future<void> _simulateScanPickup() async {
    setState(() => _isLoading = true);

    final success = await SimulationService().simulateScanQRPickup(widget.delivery.id);

    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog(
        title: 'Colis récupéré !',
        message: 'Le QR code a été scanné avec succès au point A.',
      );
      _updateStatus(DeliveryStatus.pickedUp);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du scan (simulation)'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Simulation: Scanner QR au point B (delivery)
  Future<void> _simulateScanDelivery() async {
    setState(() => _isLoading = true);

    final success = await SimulationService().simulateScanQRDelivery(widget.delivery.id);

    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog(
        title: 'Livraison effectuée !',
        message: 'Le QR code a été scanné avec succès au point B.',
      );
      _updateStatus(DeliveryStatus.delivered);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du scan (simulation)'),
          backgroundColor: AppColors.error,
        ),
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

          // Badge SIMULATION (si mode actif)
          if (SimulationService().isSimulationMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: Material(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
              ),
            ),

          // Info badge - Course en cours
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: SimulationService().isSimulationMode ? 120 : 8,
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
                    distanceKm: _mockDistance,
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

          // Bottom Actions Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLg),
                  topRight: Radius.circular(AppSizes.radiusLg),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSizes.paddingMd,
                  right: AppSizes.paddingMd,
                  top: AppSizes.paddingMd,
                  bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingMd,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // NEW: Package Info Card
                    PackageInfoCard(
                      package: widget.delivery.package,
                      price: widget.delivery.price,
                    ),
                    const SizedBox(height: AppSizes.spacingMd),

                    // NEW: Delivery Timeline Widget
                    DeliveryTimelineWidget(
                      currentStatus: _currentStatus,
                      createdAt: widget.delivery.createdAt,
                      acceptedAt: widget.delivery.acceptedAt,
                      pickedUpAt: widget.delivery.pickedUpAt,
                      deliveredAt: widget.delivery.deliveredAt,
                    ),
                    const SizedBox(height: AppSizes.spacingLg),

                    // NEW: Navigation Button (Phase 2)
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

                    // Report problem button (Enhanced in Phase 2)
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
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    switch (_currentStatus) {
      case DeliveryStatus.accepted:
        // Transition automatique rapide vers pickupInProgress - Message simple
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
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                ),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Expanded(
                child: Text(
                  'Démarrage de la course...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        );

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
            onPressed: _simulateScanPickup,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('Simuler scan Point A'),
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
            onPressed: _simulateScanDelivery,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('Simuler scan Point B'),
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
