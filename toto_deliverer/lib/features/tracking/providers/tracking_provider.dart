import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tracking_service.dart';

class TrackingState {
  final bool isConnected;
  final String? currentDeliveryId;
  final Map<String, dynamic>? lastLocation;
  final String? error;

  TrackingState({
    this.isConnected = false,
    this.currentDeliveryId,
    this.lastLocation,
    this.error,
  });

  TrackingState copyWith({
    bool? isConnected,
    String? currentDeliveryId,
    Map<String, dynamic>? lastLocation,
    String? error,
  }) {
    return TrackingState(
      isConnected: isConnected ?? this.isConnected,
      currentDeliveryId: currentDeliveryId ?? this.currentDeliveryId,
      lastLocation: lastLocation ?? this.lastLocation,
      error: error,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingService _trackingService = TrackingService();

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
    );
  }

  @override
  void dispose() {
    _trackingService.removeAllListeners();
    _trackingService.disconnect();
    super.dispose();
  }
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});
