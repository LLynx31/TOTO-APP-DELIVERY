import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/repositories/auth_repository_impl.dart';
import '../../../../domain/repositories/delivery_repository.dart';
import '../../../providers/create_delivery_provider.dart';

/// Step 4: Récapitulatif et confirmation
class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key});

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  GoogleMapController? _mapController;
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _confirmDelivery() async {
    final state = ref.read(createDeliveryProvider);

    // Validate all data is present
    if (!state.canProceedToStep4) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs requis';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // Create delivery params
      final params = CreateDeliveryParams(
        pickupAddress: state.pickupAddress!,
        pickupLatitude: state.pickupLocation!.latitude,
        pickupLongitude: state.pickupLocation!.longitude,
        deliveryAddress: state.deliveryAddress!,
        deliveryLatitude: state.deliveryLocation!.latitude,
        deliveryLongitude: state.deliveryLocation!.longitude,
        deliveryPhone: state.receiverPhone!,
        receiverName: state.receiverName!,
        packageDescription: state.packageDescription,
        packageWeight: state.packageWeight,
        specialInstructions: state.specialInstructions,
      );

      // Call use case
      final result = await ref.read(createDeliveryUsecaseProvider).call(params);

      if (!mounted) return;

      switch (result) {
        case Success():
          // Clear wizard state
          ref.read(createDeliveryProvider.notifier).reset();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison créée avec succès!'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate back to home
          context.go('/home');
        case Failure(message: final error):
          setState(() {
            _errorMessage = error;
            _isCreating = false;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Une erreur est survenue: $e';
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDeliveryProvider);

    if (state.pickupLocation == null || state.deliveryLocation == null) {
      return const Center(
        child: Text('Données incomplètes'),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSizes.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingSm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Récapitulatif',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Vérifiez les informations avant de confirmer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacingLg),

              // Map preview
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      (state.pickupLocation!.latitude + state.deliveryLocation!.latitude) / 2,
                      (state.pickupLocation!.longitude + state.deliveryLocation!.longitude) / 2,
                    ),
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Fit bounds to show both markers
                    final bounds = LatLngBounds(
                      southwest: LatLng(
                        state.pickupLocation!.latitude < state.deliveryLocation!.latitude
                            ? state.pickupLocation!.latitude
                            : state.deliveryLocation!.latitude,
                        state.pickupLocation!.longitude < state.deliveryLocation!.longitude
                            ? state.pickupLocation!.longitude
                            : state.deliveryLocation!.longitude,
                      ),
                      northeast: LatLng(
                        state.pickupLocation!.latitude > state.deliveryLocation!.latitude
                            ? state.pickupLocation!.latitude
                            : state.deliveryLocation!.latitude,
                        state.pickupLocation!.longitude > state.deliveryLocation!.longitude
                            ? state.pickupLocation!.longitude
                            : state.deliveryLocation!.longitude,
                      ),
                    );
                    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: state.pickupLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    ),
                    Marker(
                      markerId: const MarkerId('delivery'),
                      position: state.deliveryLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: [state.pickupLocation!, state.deliveryLocation!],
                      color: AppColors.primary,
                      width: 3,
                      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
              const SizedBox(height: AppSizes.spacingLg),

              // Distance and Price
              if (state.distanceKm != null && state.estimatedPrice != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.straighten,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(height: AppSizes.spacingXs),
                            Text(
                              '${state.distanceKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              'Distance',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingMd),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.payments,
                              color: AppColors.success,
                              size: 24,
                            ),
                            const SizedBox(height: AppSizes.spacingXs),
                            Text(
                              '${state.estimatedPrice!.toStringAsFixed(0)} F',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const Text(
                              'Prix estimé',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingLg),
              ],

              // Locations Section
              _buildSectionTitle('Itinéraire'),
              const SizedBox(height: AppSizes.spacingSm),
              _buildInfoCard(
                icon: Icons.location_on,
                iconColor: AppColors.success,
                title: 'Point de départ',
                value: state.pickupAddress ?? 'Non défini',
              ),
              const SizedBox(height: AppSizes.spacingSm),
              _buildInfoCard(
                icon: Icons.location_on,
                iconColor: AppColors.error,
                title: 'Point d\'arrivée',
                value: state.deliveryAddress ?? 'Non défini',
              ),
              const SizedBox(height: AppSizes.spacingLg),

              // Receiver Information
              _buildSectionTitle('Destinataire'),
              const SizedBox(height: AppSizes.spacingSm),
              _buildInfoCard(
                icon: Icons.person,
                iconColor: AppColors.primary,
                title: 'Nom',
                value: state.receiverName ?? 'Non défini',
              ),
              const SizedBox(height: AppSizes.spacingSm),
              _buildInfoCard(
                icon: Icons.phone,
                iconColor: AppColors.primary,
                title: 'Téléphone',
                value: state.receiverPhone ?? 'Non défini',
              ),
              const SizedBox(height: AppSizes.spacingLg),

              // Package Information
              _buildSectionTitle('Colis'),
              const SizedBox(height: AppSizes.spacingSm),
              _buildInfoCard(
                icon: Icons.description,
                iconColor: AppColors.primary,
                title: 'Description',
                value: state.packageDescription ?? 'Non défini',
              ),
              if (state.packageWeight != null) ...[
                const SizedBox(height: AppSizes.spacingSm),
                _buildInfoCard(
                  icon: Icons.scale,
                  iconColor: AppColors.primary,
                  title: 'Poids',
                  value: '${state.packageWeight} kg',
                ),
              ],
              if (state.specialInstructions != null) ...[
                const SizedBox(height: AppSizes.spacingSm),
                _buildInfoCard(
                  icon: Icons.note,
                  iconColor: AppColors.warning,
                  title: 'Instructions spéciales',
                  value: state.specialInstructions!,
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSizes.spacingLg),
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: AppSizes.spacingSm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100), // Space for button
            ],
          ),
        ),

        // Confirm button (fixed at bottom)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isCreating ? null : _confirmDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingMd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirmer la livraison',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingSm),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
