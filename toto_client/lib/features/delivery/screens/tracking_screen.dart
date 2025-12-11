import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'new_delivery_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String deliveryId;

  const TrackingScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Mock delivery data
  late DeliveryModel _delivery;

  // Expansion states
  bool _isParcelDetailsExpanded = false;
  bool _isDeliveryDetailsExpanded = false;

  // Mock deliverer data
  final _DelivererInfo _deliverer = const _DelivererInfo(
    name: 'Kouassi Yao',
    rating: 4.8,
    totalDeliveries: 342,
    photoUrl: null,
    phoneNumber: '+225 07 12 34 56 78',
    vehicleType: 'Moto',
    vehiclePlate: 'AB-1234-CI',
    isVerified: true,
  );

  // Mock alert data
  final List<_DeliveryAlert> _alerts = [];

  // Rating state for completed deliveries
  int? _userRating;
  final _ratingCommentController = TextEditingController();

  // Google Maps state
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _delivererLocation;

  @override
  void initState() {
    super.initState();
    _loadDelivery();
    _initializeMap();
  }

  @override
  void dispose() {
    _ratingCommentController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeMap() {
    // Initialize markers and polylines based on delivery status
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();

    // Get coordinates from delivery addresses
    final pickupLatLng = LatLng(
      _delivery.pickupAddress.latitude,
      _delivery.pickupAddress.longitude,
    );
    final deliveryLatLng = LatLng(
      _delivery.deliveryAddress.latitude,
      _delivery.deliveryAddress.longitude,
    );

    // Add pickup marker (green)
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Point de collecte',
          snippet: _delivery.pickupAddress.address,
        ),
      ),
    );

    // Add delivery marker (blue)
    _markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: deliveryLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Point de livraison',
          snippet: _delivery.deliveryAddress.address,
        ),
      ),
    );

    // Add deliverer marker (orange) - mock position between pickup and delivery
    if (_delivery.status != DeliveryStatus.delivered &&
        _delivery.status != DeliveryStatus.cancelled) {
      // Mock deliverer location - in real app, this would come from real-time updates
      double progress = _delivery.status == DeliveryStatus.pickupInProgress ? 0.3 : 0.7;
      _delivererLocation = LatLng(
        pickupLatLng.latitude + (deliveryLatLng.latitude - pickupLatLng.latitude) * progress,
        pickupLatLng.longitude + (deliveryLatLng.longitude - pickupLatLng.longitude) * progress,
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('deliverer'),
          position: _delivererLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: _deliverer.name,
            snippet: '${_deliverer.vehicleType} - ${_deliverer.vehiclePlate}',
          ),
        ),
      );

      // Add polyline showing route
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [pickupLatLng, _delivererLocation!, deliveryLatLng],
          color: AppColors.secondary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _fitMapBounds() {
    if (_markers.isEmpty || _mapController == null) return;

    // Calculate bounds to fit all markers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in _markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  void _loadDelivery() {
    // Mock data - will be replaced with real API call
    // Determine status based on delivery ID to match home screen data
    DeliveryStatus status;
    String fromAddress;
    String toAddress;
    double price;
    Duration timeSince;
    DeliveryMode mode;

    switch (widget.deliveryId) {
      case '1':
        status = DeliveryStatus.deliveryInProgress;
        fromAddress = 'Cocody Angré, Abidjan';
        toAddress = 'Plateau, Boulevard de la République, Abidjan';
        price = 3500;
        timeSince = const Duration(minutes: 25);
        mode = DeliveryMode.express;
        break;
      case '2':
        status = DeliveryStatus.pickupInProgress;
        fromAddress = 'Marcory Zone 4, Abidjan';
        toAddress = 'Yopougon, Abidjan';
        price = 2800;
        timeSince = const Duration(hours: 1);
        mode = DeliveryMode.standard;
        break;
      case '3':
      case '4':
        // Completed deliveries
        status = DeliveryStatus.delivered;
        fromAddress = 'Treichville, Abidjan';
        toAddress = 'Adjamé, Abidjan';
        price = 2500;
        timeSince = const Duration(days: 1);
        mode = DeliveryMode.standard;
        break;
      default:
        // Default to delivered for unknown IDs
        status = DeliveryStatus.delivered;
        fromAddress = 'Cocody Angré, Abidjan';
        toAddress = 'Plateau, Boulevard de la République, Abidjan';
        price = 3500;
        timeSince = const Duration(minutes: 30);
        mode = DeliveryMode.express;
    }

    _delivery = DeliveryModel(
      id: widget.deliveryId,
      customerId: 'user123',
      delivererId: 'driver456',
      package: PackageModel(
        size: PackageSize.medium,
        weight: 2.5,
      ),
      pickupAddress: AddressModel(
        address: fromAddress,
        latitude: 5.3599517,
        longitude: -3.9810303,
      ),
      deliveryAddress: AddressModel(
        address: toAddress,
        latitude: 5.3167,
        longitude: -4.0333,
      ),
      mode: mode,
      status: status,
      price: price,
      createdAt: DateTime.now().subtract(timeSince),
      qrCode: 'delivery_${widget.deliveryId}_qr',
    );
  }

  // Calculate dynamic ETA based on status and mock distance
  String _calculateETA() {
    switch (_delivery.status) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.accepted:
        return '15-20 min';
      case DeliveryStatus.pickupInProgress:
        return '8-10 min';
      case DeliveryStatus.pickedUp:
        return '12-15 min';
      case DeliveryStatus.deliveryInProgress:
        return '5-8 min';
      case DeliveryStatus.delivered:
        return 'Livré';
      case DeliveryStatus.cancelled:
        return 'Annulé';
    }
  }

  // Calculate overall progress percentage
  double _calculateProgress() {
    switch (_delivery.status) {
      case DeliveryStatus.pending:
        return 0.1;
      case DeliveryStatus.accepted:
        return 0.25;
      case DeliveryStatus.pickupInProgress:
        return 0.4;
      case DeliveryStatus.pickedUp:
        return 0.6;
      case DeliveryStatus.deliveryInProgress:
        return 0.85;
      case DeliveryStatus.delivered:
        return 1.0;
      case DeliveryStatus.cancelled:
        return 0.0;
    }
  }

  void _shareTracking() {
    final trackingUrl = 'https://toto-delivery.app/track/${_delivery.id}';
    final message =
      'Suivez votre livraison TOTO en temps réel\n'
      'ID: ${_delivery.id}\n'
      'Status: ${_delivery.status.displayName}\n'
      'ETA: ${_calculateETA()}\n'
      'Lien: $trackingUrl';

    Share.share(message, subject: 'Suivi de livraison TOTO');
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = _delivery.status == DeliveryStatus.delivered;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDelivered ? 'Livraison terminée' : AppStrings.trackDelivery),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareTracking,
            tooltip: 'Partager',
          ),
          if (!isDelivered)
            NotificationBell(
              unreadCount: 3, // TODO: Get from provider
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Conditional rendering based on delivery status
            if (isDelivered) ...[
              // Success Banner (replaces progress bar)
              _buildSuccessBanner(),
            ] else ...[
              // Global Progress Bar (for active deliveries)
              _buildGlobalProgressBar(),

              // Map Section (for active deliveries)
              _buildMapSection(),
            ],

            // Delivery Info
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Deliverer Info (modified for completed deliveries)
                  _buildDelivererInfo(),

                  const SizedBox(height: AppSizes.spacingLg),

                  // Rating Section (only for completed deliveries)
                  if (isDelivered) ...[
                    _buildRatingSection(),
                    const SizedBox(height: AppSizes.spacingLg),
                  ],

                  // Alerts Section (if any)
                  if (_alerts.isNotEmpty) ...[
                    _buildAlertsSection(),
                    const SizedBox(height: AppSizes.spacingLg),
                  ],

                  // Progress Timeline
                  _buildProgressTimeline(),

                  const SizedBox(height: AppSizes.spacingLg),

                  // Financial Summary (only for completed deliveries)
                  if (isDelivered) ...[
                    _buildFinancialSummary(),
                    const SizedBox(height: AppSizes.spacingLg),
                  ],

                  // Package Photo (if available)
                  if (_delivery.package.photoUrl != null) ...[
                    _buildPackagePhoto(),
                    const SizedBox(height: AppSizes.spacingLg),
                  ],

                  // Parcel Details (Collapsible)
                  _buildParcelDetails(),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Delivery Details (Collapsible)
                  _buildDeliveryDetails(),

                  const SizedBox(height: AppSizes.spacingLg),

                  // QR Code Section - Only show if not delivered
                  if (_delivery.status != DeliveryStatus.delivered &&
                      _delivery.status != DeliveryStatus.cancelled)
                    _buildQRCodeSection(),

                  if (_delivery.status != DeliveryStatus.delivered &&
                      _delivery.status != DeliveryStatus.cancelled)
                    const SizedBox(height: AppSizes.spacingLg),

                  // Action buttons based on delivery status
                  if (_delivery.status == DeliveryStatus.delivered)
                    _buildCompletedDeliveryActions()
                  else
                    CustomButton(
                      text: AppStrings.contactDeliverer,
                      onPressed: () {
                        // TODO: Contact deliverer
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.textWhite,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    final deliveredAt = DateTime.now(); // TODO: Get from _delivery.deliveredAt when available
    final duration = deliveredAt.difference(_delivery.createdAt);
    final durationMinutes = duration.inMinutes;

    return Container(
      color: AppColors.success.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 40,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Text(
            'Livraison réussie !',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            'Livrée le ${deliveredAt.day}/${deliveredAt.month} à ${deliveredAt.hour.toString().padLeft(2, '0')}:${deliveredAt.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            'Durée totale: $durationMinutes minutes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalProgressBar() {
    final progress = _calculateProgress();
    final progressPercent = (progress * 100).toInt();

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        AppSizes.paddingSm,
        AppSizes.paddingLg,
        AppSizes.paddingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression globale',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '$progressPercent%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                _delivery.status == DeliveryStatus.delivered
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      color: AppColors.surfaceGrey,
      child: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _delivery.pickupAddress.latitude,
                _delivery.pickupAddress.longitude,
              ),
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              // Fit bounds to show all markers
              if (_markers.length > 1) {
                _fitMapBounds();
              }
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Status overlay
          Positioned(
            top: AppSizes.paddingLg,
            left: AppSizes.paddingLg,
            right: AppSizes.paddingLg,
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
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
                          _delivery.status.displayName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          _calculateETA(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelivererInfo() {
    final isDelivered = _delivery.status == DeliveryStatus.delivered;

    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with verification badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.backgroundGrey,
                    child: _deliverer.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _deliverer.photoUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.person,
                                size: 32,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.textSecondary,
                          ),
                  ),
                  if (_deliverer.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: AppSizes.spacingMd),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _deliverer.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (_deliverer.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingXs),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_deliverer.rating}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_deliverer.totalDeliveries} livraisons',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingXs),
                    Row(
                      children: [
                        Icon(
                          _deliverer.vehicleType == 'Moto'
                              ? Icons.two_wheeler
                              : Icons.local_shipping,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_deliverer.vehicleType} • ${_deliverer.vehiclePlate}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Only show contact buttons for active deliveries
          if (!isDelivered) ...[
            const SizedBox(height: AppSizes.spacingMd),
            const Divider(),
            const SizedBox(height: AppSizes.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Call deliverer
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Message deliverer
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment s\'est passée la livraison ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _userRating = starIndex;
                  });
                },
                icon: Icon(
                  _userRating != null && starIndex <= _userRating!
                      ? Icons.star
                      : Icons.star_border,
                  size: 40,
                  color: AppColors.warning,
                ),
              );
            }),
          ),
          if (_userRating != null) ...[
            const SizedBox(height: AppSizes.spacingMd),
            TextField(
              controller: _ratingCommentController,
              decoration: const InputDecoration(
                hintText: 'Ajouter un commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.spacingMd),
            CustomButton(
              text: 'Envoyer l\'évaluation',
              onPressed: () {
                // TODO: Submit rating
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Merci pour votre évaluation !'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ] else ...[
            const SizedBox(height: AppSizes.spacingSm),
            Center(
              child: Text(
                'Pas encore noté',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    // Calculate breakdown
    final basePrice = 3000.0;
    final expressFee = _delivery.mode == DeliveryMode.express ? 500.0 : 0.0;
    final total = _delivery.price;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif financier',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          const Divider(),
          const SizedBox(height: AppSizes.spacingMd),
          _buildPriceRow('Course', basePrice),
          if (expressFee > 0) ...[
            const SizedBox(height: AppSizes.spacingSm),
            _buildPriceRow('Frais express', expressFee),
          ],
          const SizedBox(height: AppSizes.spacingMd),
          const Divider(),
          const SizedBox(height: AppSizes.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${total.toInt()} FCFA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 20,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Text(
                'Payé en espèces',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          '${amount.toInt()} FCFA',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressTimeline() {
    // Determine if delivery is completed
    final isDelivered = _delivery.status == DeliveryStatus.delivered;
    final now = DateTime.now();
    final createdTime = _delivery.createdAt;

    final steps = [
      _TimelineStep(
        title: 'Commande créée',
        icon: Icons.check_circle,
        isCompleted: true,
        time: '${createdTime.hour.toString().padLeft(2, '0')}:${createdTime.minute.toString().padLeft(2, '0')}',
      ),
      _TimelineStep(
        title: 'Livreur assigné',
        icon: Icons.person_add,
        isCompleted: true,
        time: '${createdTime.add(const Duration(minutes: 2)).hour.toString().padLeft(2, '0')}:${createdTime.add(const Duration(minutes: 2)).minute.toString().padLeft(2, '0')}',
      ),
      _TimelineStep(
        title: 'En route vers le point A',
        icon: Icons.directions_bike,
        isCompleted: _delivery.status.index >= DeliveryStatus.pickupInProgress.index,
        isCurrent: _delivery.status == DeliveryStatus.pickupInProgress,
        time: _delivery.status.index >= DeliveryStatus.pickupInProgress.index
            ? '${createdTime.add(const Duration(minutes: 5)).hour.toString().padLeft(2, '0')}:${createdTime.add(const Duration(minutes: 5)).minute.toString().padLeft(2, '0')}'
            : 'En attente',
      ),
      _TimelineStep(
        title: 'Colis récupéré au point A',
        icon: Icons.inventory_2,
        isCompleted: _delivery.status.index >= DeliveryStatus.pickedUp.index,
        isCurrent: _delivery.status == DeliveryStatus.pickedUp,
        time: _delivery.status.index >= DeliveryStatus.pickedUp.index
            ? '${createdTime.add(const Duration(minutes: 15)).hour.toString().padLeft(2, '0')}:${createdTime.add(const Duration(minutes: 15)).minute.toString().padLeft(2, '0')}'
            : 'À venir',
      ),
      _TimelineStep(
        title: 'En route vers le point B',
        icon: Icons.local_shipping,
        isCompleted: _delivery.status.index >= DeliveryStatus.deliveryInProgress.index && isDelivered,
        isCurrent: _delivery.status == DeliveryStatus.deliveryInProgress,
        time: _delivery.status == DeliveryStatus.deliveryInProgress
            ? 'En cours'
            : _delivery.status.index > DeliveryStatus.deliveryInProgress.index
                ? '${createdTime.add(const Duration(minutes: 20)).hour.toString().padLeft(2, '0')}:${createdTime.add(const Duration(minutes: 20)).minute.toString().padLeft(2, '0')}'
                : 'À venir',
      ),
      _TimelineStep(
        title: 'Livraison effectuée',
        icon: Icons.flag,
        isCompleted: isDelivered,
        time: isDelivered
            ? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
            : 'À venir',
      ),
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression de la livraison',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return _buildTimelineItem(
              step: step,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required _TimelineStep step,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator with icon
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: step.isCompleted || step.isCurrent
                    ? AppColors.primary
                    : AppColors.surfaceGrey,
                shape: BoxShape.circle,
                border: step.isCurrent
                    ? Border.all(
                        color: AppColors.primary,
                        width: 3,
                      )
                    : null,
              ),
              child: Icon(
                step.icon,
                size: 16,
                color: step.isCompleted || step.isCurrent
                    ? AppColors.textWhite
                    : AppColors.textTertiary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: step.isCompleted
                        ? [AppColors.primary, AppColors.primary]
                        : [AppColors.border, AppColors.border],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: AppSizes.spacingMd),

        // Step info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: step.isCurrent || step.isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: step.isCurrent
                                  ? AppColors.primary
                                  : step.isCompleted
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                            ),
                      ),
                    ),
                    if (step.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          'En cours',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingXs),
                Text(
                  step.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Text(
                'Alertes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          const Divider(),
          ..._alerts.map((alert) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      alert.icon,
                      color: alert.color,
                      size: 18,
                    ),
                    const SizedBox(width: AppSizes.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPackagePhoto() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo du colis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _delivery.package.photoUrl != null
                  ? Image.network(
                      _delivery.package.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceGrey,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image non disponible',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            'Photo prise lors de la récupération',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelDetails() {
    return CustomCard(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isParcelDetailsExpanded = !_isParcelDetailsExpanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Détails du colis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  _isParcelDetailsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (_isParcelDetailsExpanded) ...[
            const SizedBox(height: AppSizes.spacingMd),
            const Divider(),
            const SizedBox(height: AppSizes.spacingMd),
            _buildDetailRow(
              'Taille',
              _delivery.package.size.displayName,
            ),
            const SizedBox(height: AppSizes.spacingSm),
            _buildDetailRow(
              'Poids',
              '${_delivery.package.weight} kg',
            ),
            if (_delivery.package.description != null) ...[
              const SizedBox(height: AppSizes.spacingSm),
              _buildDetailRow(
                'Description',
                _delivery.package.description!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return CustomCard(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isDeliveryDetailsExpanded = !_isDeliveryDetailsExpanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Détails de la livraison',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  _isDeliveryDetailsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (_isDeliveryDetailsExpanded) ...[
            const SizedBox(height: AppSizes.spacingMd),
            const Divider(),
            const SizedBox(height: AppSizes.spacingMd),
            _buildDetailRow(
              'De',
              _delivery.pickupAddress.address,
            ),
            const SizedBox(height: AppSizes.spacingSm),
            _buildDetailRow(
              'À',
              _delivery.deliveryAddress.address,
            ),
            const SizedBox(height: AppSizes.spacingSm),
            _buildDetailRow(
              'Mode',
              _delivery.mode.displayName,
            ),
            const SizedBox(height: AppSizes.spacingSm),
            _buildDetailRow(
              'Prix estimé',
              '${_delivery.price.toInt()} FCFA',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedDeliveryActions() {
    return Column(
      children: [
        // Reorder button
        CustomButton(
          text: 'Commander à nouveau',
          onPressed: () {
            // Navigate to new delivery screen with pre-filled addresses
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewDeliveryScreen(
                  initialPickupAddress: _delivery.pickupAddress,
                  initialDeliveryAddress: _delivery.deliveryAddress,
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.refresh,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMd),
        // Report problem button
        OutlinedButton.icon(
          onPressed: () {
            _showReportProblemDialog();
          },
          icon: const Icon(Icons.report_problem_outlined, size: 18),
          label: const Text('Signaler un problème'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showReportProblemDialog() {
    final problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Décrivez le problème rencontré avec cette livraison :',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.spacingMd),
            TextField(
              controller: problemController,
              decoration: const InputDecoration(
                hintText: 'Détails du problème...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Submit problem report
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Votre signalement a été envoyé. Nous vous contacterons bientôt.'),
                  backgroundColor: AppColors.success,
                ),
              );
              problemController.dispose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return CustomCard(
      child: Column(
        children: [
          Text(
            AppStrings.showQRCode,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingLg),

          // QR Code
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: AppColors.textWhite,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: QrImageView(
              data: _delivery.qrCode ?? 'delivery_qr_code',
              version: QrVersions.auto,
              size: 200,
            ),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          Text(
            '${AppStrings.validUntil} 04:59',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          OutlinedButton.icon(
            onPressed: () {
              // TODO: Refresh QR code
            },
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.refreshQR),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final String time;

  _TimelineStep({
    required this.title,
    required this.icon,
    this.isCompleted = false,
    this.isCurrent = false,
    required this.time,
  });
}

class _DelivererInfo {
  final String name;
  final double rating;
  final int totalDeliveries;
  final String? photoUrl;
  final String phoneNumber;
  final String vehicleType;
  final String vehiclePlate;
  final bool isVerified;

  const _DelivererInfo({
    required this.name,
    required this.rating,
    required this.totalDeliveries,
    this.photoUrl,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehiclePlate,
    this.isVerified = false,
  });
}

class _DeliveryAlert {
  final String message;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  const _DeliveryAlert({
    required this.message,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}
