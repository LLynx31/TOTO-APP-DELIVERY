import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_model.dart';
import '../services/tracking_service.dart';

// Service provider
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final service = TrackingService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// Tracking state
class TrackingState {
  final bool isConnected;
  final DeliveryModel? currentDelivery;
  final double? delivererLatitude;
  final double? delivererLongitude;
  final DateTime? lastUpdate;
  final String? error;

  TrackingState({
    this.isConnected = false,
    this.currentDelivery,
    this.delivererLatitude,
    this.delivererLongitude,
    this.lastUpdate,
    this.error,
  });

  TrackingState copyWith({
    bool? isConnected,
    DeliveryModel? currentDelivery,
    double? delivererLatitude,
    double? delivererLongitude,
    DateTime? lastUpdate,
    String? error,
  }) {
    return TrackingState(
      isConnected: isConnected ?? this.isConnected,
      currentDelivery: currentDelivery ?? this.currentDelivery,
      delivererLatitude: delivererLatitude ?? this.delivererLatitude,
      delivererLongitude: delivererLongitude ?? this.delivererLongitude,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      error: error,
    );
  }
}

// Tracking notifier
class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingService _trackingService;

  TrackingNotifier(this._trackingService) : super(TrackingState()) {
    _initialize();
  }

  void _initialize() {
    // Écouter les mises à jour de connexion
    _trackingService.connectionStatus.listen((isConnected) {
      state = state.copyWith(isConnected: isConnected);
    });

    // Écouter les mises à jour de livraison
    _trackingService.deliveryUpdates.listen((delivery) {
      if (state.currentDelivery?.id == delivery.id) {
        state = state.copyWith(
          currentDelivery: delivery,
          lastUpdate: DateTime.now(),
        );
      }
    });

    // Écouter les mises à jour de localisation
    _trackingService.locationUpdates.listen((location) {
      state = state.copyWith(
        delivererLatitude: location.latitude,
        delivererLongitude: location.longitude,
        lastUpdate: location.timestamp,
      );
    });
  }

  // Se connecter au service de suivi
  Future<void> connect() async {
    try {
      await _trackingService.connect();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Commencer à suivre une livraison
  void startTracking(DeliveryModel delivery) {
    state = state.copyWith(
      currentDelivery: delivery,
      delivererLatitude: null,
      delivererLongitude: null,
      lastUpdate: null,
      error: null,
    );
    _trackingService.trackDelivery(delivery.id);
  }

  // Arrêter de suivre une livraison
  void stopTracking() {
    if (state.currentDelivery != null) {
      _trackingService.untrackDelivery(state.currentDelivery!.id);
    }
    state = TrackingState(isConnected: state.isConnected);
  }

  // Se déconnecter
  void disconnect() {
    _trackingService.disconnect();
    state = TrackingState();
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Tracking provider
final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final trackingService = ref.watch(trackingServiceProvider);
  return TrackingNotifier(trackingService);
});
