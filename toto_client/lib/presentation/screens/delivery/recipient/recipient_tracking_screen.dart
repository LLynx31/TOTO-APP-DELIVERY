import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../domain/entities/delivery.dart';
import '../../../providers/tracking_provider.dart';
import '../../../providers/delivery_provider.dart';
import '../../../widgets/tracking/delivery_status_timeline.dart';
import '../../../widgets/delivery/delivery_code_display.dart';

/// Écran de suivi pour le destinataire (qui a l'app)
class RecipientTrackingScreen extends ConsumerStatefulWidget {
  final String deliveryId;

  const RecipientTrackingScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<RecipientTrackingScreen> createState() =>
      _RecipientTrackingScreenState();
}

class _RecipientTrackingScreenState
    extends ConsumerState<RecipientTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _pickupLocation;
  LatLng? _deliveryLocation;
  LatLng? _delivererLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).startTracking(widget.deliveryId);
      ref
          .read(deliveryProvider(widget.deliveryId).notifier)
          .loadDelivery(widget.deliveryId);
    });
  }

  @override
  void dispose() {
    ref.read(trackingProvider.notifier).stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final deliveryState = ref.watch(deliveryProvider(widget.deliveryId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: switch (deliveryState) {
        DeliveryLoaded(:final delivery) => _buildContent(delivery, trackingState),
        DeliveryLoading() => const Center(child: CircularProgressIndicator()),
        DeliveryError(:final message) => _buildErrorView(message),
        DeliveryInitial() => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildContent(Delivery delivery, TrackingState trackingState) {
    _initializeLocations(delivery);

    return Stack(
      children: [
        // Carte en plein écran
        _buildMap(trackingState),

        // SafeArea pour le bouton retour
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingMd),
            child: _buildBackButton(),
          ),
        ),

        // Panneau d'informations scrollable
        DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle pour glisser
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSizes.spacingLg),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Titre principal
                    Text(
                      'Votre colis arrive ! 📦',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    // Info expéditeur
                    Text(
                      'De: ${delivery.pickupLocation.address}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Timeline de statut
                    DeliveryStatusTimeline(currentStatus: delivery.status),

                    const SizedBox(height: AppSizes.spacingXl),

                    // QR Code de validation
                    _buildQRCodeSection(delivery),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Code 4 chiffres
                    if (delivery.deliveryCode != null)
                      DeliveryCodeDisplay(
                        code: delivery.deliveryCode!,
                        title: 'Code de validation',
                        description:
                            'Communiquez ce code au livreur si le scan QR ne fonctionne pas',
                      ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Bouton d'aide
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implémenter contact support
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support: +225 XX XX XX XX'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.info),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingMd,
                        ),
                      ),
                      icon: const Icon(
                        Icons.help_outline,
                        color: AppColors.info,
                      ),
                      label: const Text(
                        'Besoin d\'aide ?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingLg),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQRCodeSection(Delivery delivery) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'QR Code de livraison',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: QrImageView(
              data: delivery.qrCodes.delivery,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Text(
            'Présentez ce QR code au livreur',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _initializeLocations(Delivery delivery) {
    _pickupLocation ??= LatLng(
      delivery.pickupLocation.latitude,
      delivery.pickupLocation.longitude,
    );
    _deliveryLocation ??= LatLng(
      delivery.deliveryLocation.latitude,
      delivery.deliveryLocation.longitude,
    );
  }

  Widget _buildMap(TrackingState trackingState) {
    if (trackingState.currentLocation != null) {
      _delivererLocation = LatLng(
        trackingState.currentLocation!.latitude,
        trackingState.currentLocation!.longitude,
      );
    }

    _updateMarkers();
    _updatePolyline();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _deliveryLocation ?? const LatLng(0, 0),
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitMapToMarkers();
      },
    );
  }

  void _updateMarkers() {
    _markers.clear();

    // Marker pickup (vert)
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Point de ramassage'),
        ),
      );
    }

    // Marker delivery (rouge) - destination du destinataire
    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(title: 'Votre adresse'),
        ),
      );
    }

    // Marker livreur (bleu)
    if (_delivererLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('deliverer'),
          position: _delivererLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(title: 'Livreur'),
        ),
      );
    }
  }

  void _updatePolyline() {
    _polylines.clear();

    if (_delivererLocation != null && _deliveryLocation != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_delivererLocation!, _deliveryLocation!],
          color: AppColors.primary,
          width: 4,
        ),
      );
    }
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;

    LatLngBounds? bounds;
    for (final marker in _markers) {
      if (bounds == null) {
        bounds = LatLngBounds(
          southwest: marker.position,
          northeast: marker.position,
        );
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(
            bounds.southwest.latitude < marker.position.latitude
                ? bounds.southwest.latitude
                : marker.position.latitude,
            bounds.southwest.longitude < marker.position.longitude
                ? bounds.southwest.longitude
                : marker.position.longitude,
          ),
          northeast: LatLng(
            bounds.northeast.latitude > marker.position.latitude
                ? bounds.northeast.latitude
                : marker.position.latitude,
            bounds.northeast.longitude > marker.position.longitude
                ? bounds.northeast.longitude
                : marker.position.longitude,
          ),
        );
      }
    }

    if (bounds != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.spacingLg),
            Text(
              'Erreur',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
