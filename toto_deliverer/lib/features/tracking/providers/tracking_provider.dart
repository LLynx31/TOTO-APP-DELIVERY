import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tracking_service.dart';
import '../../../core/services/location_tracking_service.dart';

class TrackingState {
  final bool isConnected;
  final bool isLocationTracking;
  final String? currentDeliveryId;
  final Map<String, dynamic>? lastLocation;
  final DateTime? lastUpdateTime;
  final String? error;

  TrackingState({
    this.isConnected = false,
    this.isLocationTracking = false,
    this.currentDeliveryId,
    this.lastLocation,
    this.lastUpdateTime,
    this.error,
  });

  TrackingState copyWith({
    bool? isConnected,
    bool? isLocationTracking,
    String? currentDeliveryId,
    Map<String, dynamic>? lastLocation,
    DateTime? lastUpdateTime,
    String? error,
  }) {
    return TrackingState(
      isConnected: isConnected ?? this.isConnected,
      isLocationTracking: isLocationTracking ?? this.isLocationTracking,
      currentDeliveryId: currentDeliveryId ?? this.currentDeliveryId,
      lastLocation: lastLocation ?? this.lastLocation,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      error: error,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingService _trackingService = TrackingService();
  final LocationTrackingService _locationService = LocationTrackingService();

  TrackingNotifier() : super(TrackingState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _trackingService.onStatusUpdate((data) {
      // Gérer les mises à jour de statut
    });

    _trackingService.onMessage((data) {
      // Gérer les messages
    });

    _trackingService.onError((error) {
      state = state.copyWith(error: error.toString());
    });
  }

  // Connecter au WebSocket
  Future<void> connect() async {
    try {
      await _trackingService.connect();
      state = state.copyWith(
        isConnected: _trackingService.isConnected,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Déconnecter
  void disconnect() {
    _trackingService.disconnect();
    state = state.copyWith(
      isConnected: false,
      currentDeliveryId: null,
    );
  }

  // Rejoindre une room de livraison
  void joinDeliveryRoom(String deliveryId) {
    _trackingService.joinDeliveryRoom(deliveryId);
    state = state.copyWith(currentDeliveryId: deliveryId);
  }

  // Quitter une room de livraison
  void leaveDeliveryRoom(String deliveryId) {
    _trackingService.leaveDeliveryRoom(deliveryId);
    if (state.currentDeliveryId == deliveryId) {
      state = state.copyWith(currentDeliveryId: null);
    }
  }

  // Mettre à jour la position
  void updateLocation(String deliveryId, double latitude, double longitude) {
    _trackingService.updateLocation(deliveryId, latitude, longitude);
    state = state.copyWith(
      lastLocation: {
        'deliveryId': deliveryId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
      lastUpdateTime: DateTime.now(),
    );
  }

  /// Démarre le tracking automatique de localisation
  Future<bool> startLocationTracking() async {
    if (state.currentDeliveryId == null) {
      state = state.copyWith(error: 'Aucune livraison active');
      return false;
    }

    final success = await _locationService.startTracking(
      onUpdate: (lat, lng, speed, heading) {
        // Envoyer la position au serveur via WebSocket
        if (state.currentDeliveryId != null) {
          updateLocation(state.currentDeliveryId!, lat, lng);
        }
      },
    );

    if (success) {
      state = state.copyWith(
        isLocationTracking: true,
        error: null,
      );
    } else {
      state = state.copyWith(
        error: 'Impossible de démarrer le tracking GPS',
      );
    }

    return success;
  }

  /// Arrête le tracking automatique de localisation
  void stopLocationTracking() {
    _locationService.stopTracking();
    state = state.copyWith(isLocationTracking: false);
  }

  /// Envoie manuellement la position actuelle
  Future<void> sendCurrentLocation() async {
    if (state.currentDeliveryId == null) {
      state = state.copyWith(error: 'Aucune livraison active');
      return;
    }

    final success = await _locationService.sendCurrentPosition();
    if (!success) {
      state = state.copyWith(error: 'Impossible d\'obtenir la position GPS');
    }
  }

  /// Vérifie le statut des permissions de localisation
  Future<String> checkLocationPermission() async {
    final permission = await _locationService.getPermissionStatus();
    return permission.toString();
  }

  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  @override
  void dispose() {
    _locationService.dispose();
    _trackingService.removeAllListeners();
    _trackingService.disconnect();
    super.dispose();
  }
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});
