import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/hybrid_delivery_service.dart';
import '../../core/utils/delivery_utils.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/utils/loading_overlay.dart';
import '../../core/utils/error_messages.dart';
import '../../shared/models/delivery_model.dart';
import '../../shared/widgets/widgets.dart';
import '../tracking/tracking_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final DeliveryModel delivery;
  final int remainingQuota;

  const CourseDetailsScreen({
    super.key,
    required this.delivery,
    required this.remainingQuota,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final _hybridDeliveryService = HybridDeliveryService();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    // Si la course est déjà en cours, rediriger vers le tracking
    if (widget.delivery.status != DeliveryStatus.pending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingScreen(
              delivery: widget.delivery,
            ),
          ),
        );
      });
    } else {
      _initializeMap();
    }
  }

  void _initializeMap() {
    // Create markers for pickup and delivery locations
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.delivery.pickupAddress.latitude,
          widget.delivery.pickupAddress.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Point A - Collecte',
          snippet: widget.delivery.pickupAddress.address,
        ),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(
          widget.delivery.deliveryAddress.latitude,
          widget.delivery.deliveryAddress.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Point B - Livraison',
          snippet: widget.delivery.deliveryAddress.address,
        ),
      ),
    };

    // Create a polyline connecting the two points
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(
            widget.delivery.pickupAddress.latitude,
            widget.delivery.pickupAddress.longitude,
          ),
          LatLng(
            widget.delivery.deliveryAddress.latitude,
            widget.delivery.deliveryAddress.longitude,
          ),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  Future<void> _acceptCourse() async {
    // Check if deliverer has quota
    if (widget.remainingQuota <= 0) {
      ToastUtils.showWarning(
        context,
        AppStrings.insufficientQuota,
        title: 'Quota insuffisant',
      );
      return;
    }

    LoadingOverlay.show(context, message: 'Acceptation de la course...');

    try {
      print('📦 CourseDetailsScreen: Acceptation de la course ${widget.delivery.id}...');

      // Appeler l'API via HybridDeliveryService
      final acceptedDelivery = await _hybridDeliveryService.acceptDelivery(widget.delivery.id);

      if (!mounted) return;

      print('✅ CourseDetailsScreen: Course acceptée avec succès!');
      await LoadingOverlay.hide();

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 64,
            ),
            title: const Text(
              'Course acceptée !',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Votre quota a été mis à jour',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingMd),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.delivery_dining,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        'Quota restant : ${widget.remainingQuota - 1}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              CustomButton(
                text: 'Commencer la course',
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to dashboard with result
                  // Navigate to tracking screen with updated delivery
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackingScreen(
                        delivery: acceptedDelivery,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('❌ CourseDetailsScreen: Erreur lors de l\'acceptation: $e');

      // Always hide loading overlay first
      await LoadingOverlay.hide();

      if (!mounted) return;

      ToastUtils.showError(
        context,
        ErrorMessages.deliveryError(e),
        title: 'Échec d\'acceptation',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.courseDetails,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 80, // Espace pour le bouton fixe en bas
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Section
                SizedBox(
                  height: 300, // Hauteur fixe pour la carte
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (widget.delivery.pickupAddress.latitude +
                                widget.delivery.deliveryAddress.latitude) /
                            2,
                        (widget.delivery.pickupAddress.longitude +
                                widget.delivery.deliveryAddress.longitude) /
                            2,
                      ),
                      zoom: 12,
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
                ),

                // Course Details Section
                Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course ID and Mode
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DeliveryUtils.formatDeliveryIdWithPrefix(widget.delivery.id),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                              vertical: AppSizes.paddingSm,
                            ),
                            decoration: BoxDecoration(
                              color: widget.delivery.mode == DeliveryMode.express
                                  ? AppColors.express.withValues(alpha: 0.1)
                                  : AppColors.standard.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.delivery.mode == DeliveryMode.express
                                      ? Icons.flash_on
                                      : Icons.local_shipping_outlined,
                                  size: 16,
                                  color:
                                      widget.delivery.mode == DeliveryMode.express
                                          ? AppColors.express
                                          : AppColors.standard,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.delivery.mode == DeliveryMode.express
                                      ? AppStrings.express
                                      : AppStrings.standard,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: widget.delivery.mode ==
                                                DeliveryMode.express
                                            ? AppColors.express
                                            : AppColors.standard,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.spacingLg),

                      // Pickup Address
                      _buildAddressCard(
                        icon: Icons.trip_origin,
                        iconColor: AppColors.success,
                        title: AppStrings.from,
                        address: widget.delivery.pickupAddress.address,
                      ),

                      const SizedBox(height: AppSizes.spacingMd),

                      // Delivery Address
                      _buildAddressCard(
                        icon: Icons.location_on,
                        iconColor: AppColors.error,
                        title: AppStrings.to,
                        address: widget.delivery.deliveryAddress.address,
                      ),

                      const SizedBox(height: AppSizes.spacingLg),

                      // Package Photo (if available) - displayed separately like in client app
                      if (widget.delivery.package.photoUrl != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Photo du colis:',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: AppSizes.spacingSm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                child: Image.network(
                                  widget.delivery.package.photoUrl!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: 150,
                                    color: AppColors.backgroundGrey,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 48,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingMd),
                      ],

                      // Package Details (Colis) - matching client app format
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Colis:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.spacingMd),

                            // Taille (Size + Weight combined like client app)
                            _buildInfoRow(
                              context,
                              label: 'Taille:',
                              value: '${widget.delivery.package.size.displayName}, ${widget.delivery.package.weight}kg',
                            ),

                            // Description (if available)
                            if (widget.delivery.package.description != null &&
                                widget.delivery.package.description!.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.spacingSm),
                              _buildInfoRow(
                                context,
                                label: 'Description:',
                                value: widget.delivery.package.description!,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingMd),

                      // Delivery Mode (matching client app format with duration)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                context,
                                label: 'Mode:',
                                value: widget.delivery.mode.displayName,
                              ),
                            ),
                            Text(
                              widget.delivery.mode.duration,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingLg),

                      // Price Breakdown
                      _buildPriceBreakdown(),

                      const SizedBox(height: AppSizes.spacingMd),

                      // Payment info - matching client app
                      Container(
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
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: AppSizes.iconSizeMd,
                            ),
                            const SizedBox(width: AppSizes.spacingMd),
                            Expanded(
                              child: Text(
                                AppStrings.paymentAtDelivery,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.info,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingXl),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Accept Button (Fixed at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: CustomButton(
                text: AppStrings.acceptCourse,
                onPressed: _acceptCourse,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSm),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSizes.spacingXs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    // Calculate individual price components
    double basePrice = 1000;

    // Size multiplier
    double sizeMultiplier = 1.0;
    switch (widget.delivery.package.size) {
      case PackageSize.small:
        sizeMultiplier = 0.8;
        break;
      case PackageSize.medium:
        sizeMultiplier = 1.0;
        break;
      case PackageSize.large:
        sizeMultiplier = 1.5;
        break;
    }
    final sizePrice = basePrice * sizeMultiplier;

    // Weight addition
    final weight = widget.delivery.package.weight;
    final weightPrice = weight * 200;

    // Insurance
    final insurancePrice = widget.delivery.hasInsurance ? 500.0 : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Détails du prix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  '${widget.delivery.price.toInt()} FCFA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingMd),
          const Divider(),
          const SizedBox(height: AppSizes.spacingMd),

          // Base price (size)
          _buildPriceItem(
            icon: Icons.inventory_2_outlined,
            label: 'Base (${widget.delivery.package.size.displayName})',
            amount: sizePrice,
          ),

          // Weight
          if (weight > 0) ...[
            const SizedBox(height: AppSizes.spacingSm),
            _buildPriceItem(
              icon: Icons.scale_outlined,
              label: 'Poids (${weight.toStringAsFixed(1)} kg)',
              amount: weightPrice,
            ),
          ],

          // Express mode
          if (widget.delivery.mode == DeliveryMode.express) ...[
            const SizedBox(height: AppSizes.spacingSm),
            _buildPriceItem(
              icon: Icons.flash_on,
              label: 'Mode Express (+50%)',
              amount: (sizePrice + weightPrice) * 0.5,
              isHighlight: true,
            ),
          ],

          // Insurance
          if (widget.delivery.hasInsurance) ...[
            const SizedBox(height: AppSizes.spacingSm),
            _buildPriceItem(
              icon: Icons.shield_outlined,
              label: 'Assurance',
              amount: insurancePrice,
            ),
          ],

          const SizedBox(height: AppSizes.spacingMd),

          // Info note
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSizes.spacingSm),
                Expanded(
                  child: Text(
                    'Le prix final peut varier selon la distance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem({
    required IconData icon,
    required String label,
    required double amount,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlight ? AppColors.secondary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isHighlight ? AppColors.secondary : AppColors.textSecondary,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
        Text(
          '${amount.toInt()} FCFA',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isHighlight ? AppColors.secondary : AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
