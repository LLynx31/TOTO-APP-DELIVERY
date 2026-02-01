import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/delivery.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/tracking/delivery_status_timeline.dart';
import '../../widgets/tracking/deliverer_info_card.dart';
import '../../widgets/tracking/estimated_arrival_card.dart';

/// Écran de tracking en temps réel d'une livraison
class TrackingScreen extends ConsumerStatefulWidget {
  final String deliveryId;

  const TrackingScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Positions par défaut (seront mises à jour avec les vraies données)
  LatLng? _pickupLocation;
  LatLng? _deliveryLocation;
  LatLng? _delivererLocation;

  @override
  void initState() {
    super.initState();
    // Démarrer le tracking au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).startTracking(widget.deliveryId);
      // Charger les détails de la livraison
      ref.read(deliveryProvider(widget.deliveryId).notifier).loadDelivery(widget.deliveryId);
    });
  }

  @override
  void dispose() {
    // Arrêter le tracking en quittant
    ref.read(trackingProvider.notifier).stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final deliveryState = ref.watch(deliveryProvider(widget.deliveryId));

    return Scaffold(
      body: switch (deliveryState) {
        DeliveryLoaded(:final delivery) => Builder(
            builder: (context) {
              // Initialiser les positions à partir de la livraison
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

                  // Panneau d'informations en bas (draggable)
                  _buildBottomSheet(delivery, trackingState),
                ],
              );
            },
          ),
        DeliveryLoading() => const Center(child: CircularProgressIndicator()),
        DeliveryError(:final message) => _buildErrorView(message),
        DeliveryInitial() => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// Initialise les localisations à partir des données de la livraison
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

  /// Construit la carte Google Maps
  Widget _buildMap(TrackingState trackingState) {
    // Mettre à jour la position du livreur si disponible
    if (trackingState.currentLocation != null) {
      _delivererLocation = LatLng(
        trackingState.currentLocation!.latitude,
        trackingState.currentLocation!.longitude,
      );
    }

    // Créer les markers
    _updateMarkers();

    // Créer la polyline si on a toutes les positions
    _updatePolyline();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _pickupLocation ?? const LatLng(0, 0),
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitMapToMarkers();
      },
    );
  }

  /// Met à jour les markers sur la carte
  void _updateMarkers() {
    _markers.clear();

    // Marker pickup (vert)
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Point de ramassage'),
        ),
      );
    }

    // Marker delivery (rouge)
    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Point de livraison'),
        ),
      );
    }

    // Marker deliverer (bleu)
    if (_delivererLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('deliverer'),
          position: _delivererLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Livreur'),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
  }

  /// Met à jour la polyline entre les points
  void _updatePolyline() {
    _polylines.clear();

    if (_pickupLocation != null && _deliveryLocation != null) {
      final points = <LatLng>[_pickupLocation!];

      // Ajouter la position du livreur si disponible
      if (_delivererLocation != null) {
        points.add(_delivererLocation!);
      }

      points.add(_deliveryLocation!);

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 4,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      );
    }
  }

  /// Ajuste la caméra pour montrer tous les markers
  void _fitMapToMarkers() {
    if (_mapController == null) return;

    final markers = [_pickupLocation, _deliveryLocation, _delivererLocation]
        .where((loc) => loc != null)
        .cast<LatLng>()
        .toList();

    if (markers.isEmpty) return;

    // Calculer les bounds
    double minLat = markers.first.latitude;
    double maxLat = markers.first.latitude;
    double minLng = markers.first.longitude;
    double maxLng = markers.first.longitude;

    for (final marker in markers) {
      if (marker.latitude < minLat) minLat = marker.latitude;
      if (marker.latitude > maxLat) maxLat = marker.latitude;
      if (marker.longitude < minLng) minLng = marker.longitude;
      if (marker.longitude > maxLng) maxLng = marker.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  /// Bouton retour personnalisé
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
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Panneau d'informations draggable en bas
  Widget _buildBottomSheet(Delivery delivery, TrackingState trackingState) {
    final isWaitingForDeliverer = delivery.deliverer == null &&
        delivery.status == DeliveryStatus.pending;

    return DraggableScrollableSheet(
      initialChildSize: isWaitingForDeliverer ? 0.45 : 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSizes.spacingMd),
            children: [
              // Handle pour indiquer que c'est draggable
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Carte "En attente de livreur" si pas encore assigné
              if (isWaitingForDeliverer)
                _buildWaitingForDelivererCard(delivery),

              // Indicateur de connexion (seulement si livreur assigné)
              if (!isWaitingForDeliverer && !trackingState.isConnected)
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacingSm),
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trackingState.isConnecting
                            ? Icons.sync
                            : Icons.wifi_off,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Expanded(
                        child: Text(
                          trackingState.isConnecting
                              ? 'Connexion au serveur...'
                              : 'Déconnecté - Reconnexion...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Carte d'estimation d'arrivée (seulement si livreur assigné)
              if (!isWaitingForDeliverer)
                EstimatedArrivalCard(
                  estimatedMinutes: _calculateEstimatedMinutes(trackingState),
                  distanceKm: _calculateDistance(trackingState),
                  isLoading: trackingState.isConnecting,
                ),

              if (!isWaitingForDeliverer)
                const SizedBox(height: AppSizes.spacingMd),

              // Timeline de statut
              DeliveryStatusTimeline(
                currentStatus: trackingState.currentStatus ?? delivery.status,
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Informations du livreur (si assigné)
              if (delivery.deliverer != null)
                DelivererInfoCard(
                  delivererName: delivery.deliverer!.fullName,
                  delivererPhone: delivery.deliverer!.phoneNumber,
                  delivererPhoto: delivery.deliverer!.photoUrl,
                  rating: delivery.deliverer!.rating,
                  vehicleInfo: delivery.deliverer!.vehicleType ?? 'Moto',
                ),

              const SizedBox(height: AppSizes.spacingMd),

              // Détails de la livraison
              _buildDeliveryDetails(delivery),

              const SizedBox(height: AppSizes.spacingLg),

              // Bouton annuler (seulement si en attente)
              if (isWaitingForDeliverer)
                _buildCancelButton(delivery),
            ],
          ),
        );
      },
    );
  }

  /// Carte affichée quand en attente d'un livreur
  Widget _buildWaitingForDelivererCard(Delivery delivery) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Animation de recherche
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delivery_dining,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          const Text(
            'Recherche d\'un livreur...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            'Votre demande de livraison est en cours de traitement.\nUn livreur sera bientôt assigné.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          // Bouton pour voir le QR code de récupération
          ElevatedButton.icon(
            onPressed: () {
              context.push('/delivery/${delivery.id}/qr?type=pickup');
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('Voir le QR code de récupération'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLg,
                vertical: AppSizes.paddingMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton pour annuler la livraison
  Widget _buildCancelButton(Delivery delivery) {
    return OutlinedButton.icon(
      onPressed: () => _showCancelDialog(delivery),
      icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
      label: const Text('Annuler la livraison'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLg,
          vertical: AppSizes.paddingMd,
        ),
      ),
    );
  }

  /// Dialogue de confirmation d'annulation
  void _showCancelDialog(Delivery delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la livraison'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette livraison ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implémenter l'annulation via l'API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Livraison annulée'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  /// Section des détails de livraison
  Widget _buildDeliveryDetails(Delivery delivery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails de la livraison',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMd),

        _buildDetailRow(
          Icons.inventory_2_outlined,
          'Colis',
          delivery.package.description ?? 'Standard',
        ),
        _buildDetailRow(
          Icons.location_on_outlined,
          'Ramassage',
          delivery.pickupLocation.address,
        ),
        _buildDetailRow(
          Icons.location_on,
          'Livraison',
          delivery.deliveryLocation.address,
        ),
        _buildDetailRow(
          Icons.person_outline,
          'Destinataire',
          delivery.package.receiverName,
        ),
        _buildDetailRow(
          Icons.phone_outlined,
          'Téléphone',
          delivery.package.receiverPhone,
        ),
        if (delivery.package.weight != null)
          _buildDetailRow(
            Icons.scale_outlined,
            'Poids',
            '${delivery.package.weight!.toStringAsFixed(1)} kg',
          ),
      ],
    );
  }

  /// Ligne de détail
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: AppSizes.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Vue d'erreur
  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  /// Calcule le temps estimé en minutes
  /// TODO: Implémenter le vrai calcul avec l'API
  int? _calculateEstimatedMinutes(TrackingState trackingState) {
    if (_delivererLocation == null || _deliveryLocation == null) {
      return null;
    }

    // Calcul simplifié basé sur la distance
    final distance = _calculateDistance(trackingState);
    if (distance == null) return null;

    // Vitesse moyenne estimée: 30 km/h en ville
    final minutes = (distance / 30.0 * 60).round();
    return minutes;
  }

  /// Calcule la distance entre le livreur et la destination
  double? _calculateDistance(TrackingState trackingState) {
    if (_delivererLocation == null || _deliveryLocation == null) {
      return null;
    }

    // Formule haversine simplifiée
    const double earthRadius = 6371; // km
    final lat1 = _delivererLocation!.latitude * 3.14159 / 180;
    final lat2 = _deliveryLocation!.latitude * 3.14159 / 180;
    final dLat = lat2 - lat1;
    final dLng = (_deliveryLocation!.longitude - _delivererLocation!.longitude) * 3.14159 / 180;

    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        lat1.abs() * lat2.abs() * (dLng / 2).abs() * (dLng / 2).abs();
    final c = 2 * (a.abs().clamp(0.0, 1.0));

    return earthRadius * c;
  }
}
