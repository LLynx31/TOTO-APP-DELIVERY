import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// État pour la création de livraison (wizard)
class CreateDeliveryState {
  // Step 1: Pickup Location
  final LatLng? pickupLocation;
  final String? pickupAddress;

  // Step 2: Delivery Location
  final LatLng? deliveryLocation;
  final String? deliveryAddress;

  // Step 3: Package Details
  final String? receiverName;
  final String? receiverPhone;
  final String? packageDescription;
  final double? packageWeight;
  final String? specialInstructions;

  // Calculated
  final double? distanceKm;
  final double? estimatedPrice;

  const CreateDeliveryState({
    this.pickupLocation,
    this.pickupAddress,
    this.deliveryLocation,
    this.deliveryAddress,
    this.receiverName,
    this.receiverPhone,
    this.packageDescription,
    this.packageWeight,
    this.specialInstructions,
    this.distanceKm,
    this.estimatedPrice,
  });

  CreateDeliveryState copyWith({
    LatLng? pickupLocation,
    String? pickupAddress,
    LatLng? deliveryLocation,
    String? deliveryAddress,
    String? receiverName,
    String? receiverPhone,
    String? packageDescription,
    double? packageWeight,
    String? specialInstructions,
    double? distanceKm,
    double? estimatedPrice,
  }) {
    return CreateDeliveryState(
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      packageDescription: packageDescription ?? this.packageDescription,
      packageWeight: packageWeight ?? this.packageWeight,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    );
  }

  bool get isPickupComplete =>
      pickupLocation != null && pickupAddress != null && pickupAddress!.isNotEmpty;

  bool get isDeliveryComplete =>
      deliveryLocation != null && deliveryAddress != null && deliveryAddress!.isNotEmpty;

  bool get isPackageDetailsComplete =>
      receiverName != null &&
      receiverName!.isNotEmpty &&
      receiverPhone != null &&
      receiverPhone!.isNotEmpty &&
      packageDescription != null &&
      packageDescription!.isNotEmpty;

  bool get canProceedToStep2 => isPickupComplete;
  bool get canProceedToStep3 => isPickupComplete && isDeliveryComplete;
  bool get canProceedToStep4 => isPickupComplete && isDeliveryComplete && isPackageDetailsComplete;
}

/// Notifier pour gérer la création de livraison
class CreateDeliveryNotifier extends StateNotifier<CreateDeliveryState> {
  CreateDeliveryNotifier() : super(const CreateDeliveryState());

  /// Step 1: Définir le point de départ
  void setPickupLocation(LatLng location, String address) {
    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
    );
    _calculateDistanceAndPrice();
  }

  /// Step 2: Définir le point d'arrivée
  void setDeliveryLocation(LatLng location, String address) {
    state = state.copyWith(
      deliveryLocation: location,
      deliveryAddress: address,
    );
    _calculateDistanceAndPrice();
  }

  /// Step 3: Définir les détails du colis
  void setPackageDetails({
    required String receiverName,
    required String receiverPhone,
    required String packageDescription,
    double? packageWeight,
    String? specialInstructions,
  }) {
    state = state.copyWith(
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      packageDescription: packageDescription,
      packageWeight: packageWeight,
      specialInstructions: specialInstructions,
    );
  }

  /// Calculer la distance et le prix
  void _calculateDistanceAndPrice() {
    if (state.pickupLocation == null || state.deliveryLocation == null) {
      return;
    }

    // Calcul de la distance (formule de Haversine simplifiée)
    final distance = _calculateDistance(
      state.pickupLocation!.latitude,
      state.pickupLocation!.longitude,
      state.deliveryLocation!.latitude,
      state.deliveryLocation!.longitude,
    );

    // Prix: 1000 FCFA de base + 500 FCFA par km
    final price = 1000 + (distance * 500);

    state = state.copyWith(
      distanceKm: distance,
      estimatedPrice: price,
    );
  }

  /// Calculer la distance entre deux points (en km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * (sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return double.parse(distance.toStringAsFixed(2));
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  /// Réinitialiser le wizard
  void reset() {
    state = const CreateDeliveryState();
  }
}

/// Provider pour la création de livraison
final createDeliveryProvider =
    StateNotifierProvider<CreateDeliveryNotifier, CreateDeliveryState>((ref) {
  return CreateDeliveryNotifier();
});
