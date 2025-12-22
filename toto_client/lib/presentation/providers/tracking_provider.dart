import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/injection.dart';
import '../../core/websocket/websocket_service.dart';
import '../../core/websocket/websocket_models.dart';
import '../../domain/entities/delivery.dart';

/// État du tracking en temps réel
class TrackingState {
  final bool isConnected;
  final bool isConnecting;
  final LocationUpdate? currentLocation;
  final List<LocationUpdate> locationHistory;
  final DeliveryStatus? currentStatus;
  final String? currentDeliveryId;
  final String? errorMessage;
  final DateTime? lastUpdateTime;

  const TrackingState({
    this.isConnected = false,
    this.isConnecting = false,
    this.currentLocation,
    this.locationHistory = const [],
    this.currentStatus,
    this.currentDeliveryId,
    this.errorMessage,
    this.lastUpdateTime,
  });

  TrackingState copyWith({
    bool? isConnected,
    bool? isConnecting,
    LocationUpdate? currentLocation,
    List<LocationUpdate>? locationHistory,
    DeliveryStatus? currentStatus,
    String? currentDeliveryId,
    String? errorMessage,
    DateTime? lastUpdateTime,
  }) {
    return TrackingState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      currentLocation: currentLocation ?? this.currentLocation,
      locationHistory: locationHistory ?? this.locationHistory,
      currentStatus: currentStatus ?? this.currentStatus,
      currentDeliveryId: currentDeliveryId ?? this.currentDeliveryId,
      errorMessage: errorMessage,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  /// Réinitialise l'état à l'état initial
  TrackingState reset() {
    return const TrackingState();
  }

  @override
  String toString() {
    return 'TrackingState(connected: $isConnected, deliveryId: $currentDeliveryId, location: $currentLocation, status: $currentStatus)';
  }
}

/// Notifier pour gérer le tracking en temps réel
class TrackingNotifier extends StateNotifier<TrackingState> {
  final WebSocketService _webSocketService;

  // Subscriptions aux streams WebSocket
  StreamSubscription<LocationUpdate>? _locationSubscription;
  StreamSubscription<DeliveryStatusUpdate>? _statusSubscription;
  StreamSubscription<WebSocketConnectionEvent>? _connectionSubscription;

  TrackingNotifier(this._webSocketService) : super(const TrackingState());

  /// Démarre le tracking d'une livraison
  Future<void> startTracking(String deliveryId) async {
    if (state.currentDeliveryId == deliveryId && state.isConnected) {
      debugPrint('[TrackingProvider] Already tracking delivery: $deliveryId');
      return;
    }

    debugPrint('[TrackingProvider] Starting tracking for delivery: $deliveryId');

    state = state.copyWith(
      isConnecting: true,
      currentDeliveryId: deliveryId,
      errorMessage: null,
    );

    try {
      // Connexion au WebSocket
      await _webSocketService.connect(deliveryId: deliveryId);

      // S'abonner aux événements
      _subscribeToEvents();

      debugPrint('[TrackingProvider] Successfully started tracking');
    } catch (e) {
      debugPrint('[TrackingProvider] Failed to start tracking: $e');
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: 'Échec de la connexion: $e',
      );
    }
  }

  /// S'abonne aux événements WebSocket
  void _subscribeToEvents() {
    // Annuler les abonnements précédents
    _cancelSubscriptions();

    // S'abonner aux mises à jour de localisation
    _locationSubscription = _webSocketService.locationStream.listen(
      _handleLocationUpdate,
      onError: (error) {
        debugPrint('[TrackingProvider] Location stream error: $error');
        state = state.copyWith(
          errorMessage: 'Erreur de réception de localisation: $error',
        );
      },
    );

    // S'abonner aux mises à jour de statut
    _statusSubscription = _webSocketService.statusStream.listen(
      _handleStatusUpdate,
      onError: (error) {
        debugPrint('[TrackingProvider] Status stream error: $error');
        state = state.copyWith(
          errorMessage: 'Erreur de réception de statut: $error',
        );
      },
    );

    // S'abonner aux événements de connexion
    _connectionSubscription = _webSocketService.connectionStream.listen(
      _handleConnectionEvent,
      onError: (error) {
        debugPrint('[TrackingProvider] Connection stream error: $error');
      },
    );
  }

  /// Gère les mises à jour de localisation
  void _handleLocationUpdate(LocationUpdate update) {
    debugPrint('[TrackingProvider] Location update: ${update.latitude}, ${update.longitude}');

    // Ajouter à l'historique (garder max 100 points)
    final history = List<LocationUpdate>.from(state.locationHistory);
    history.add(update);
    if (history.length > 100) {
      history.removeAt(0);
    }

    state = state.copyWith(
      currentLocation: update,
      locationHistory: history,
      lastUpdateTime: update.timestamp,
      errorMessage: null, // Clear error on successful update
    );
  }

  /// Gère les mises à jour de statut
  void _handleStatusUpdate(DeliveryStatusUpdate update) {
    debugPrint('[TrackingProvider] Status update: ${update.newStatus}');

    state = state.copyWith(
      currentStatus: update.newStatus,
      lastUpdateTime: update.timestamp,
      errorMessage: null,
    );
  }

  /// Gère les événements de connexion
  void _handleConnectionEvent(WebSocketConnectionEvent event) {
    debugPrint('[TrackingProvider] Connection event: ${event.status}');

    switch (event.status) {
      case WebSocketConnectionStatus.connecting:
        state = state.copyWith(
          isConnecting: true,
          isConnected: false,
        );
        break;

      case WebSocketConnectionStatus.connected:
        state = state.copyWith(
          isConnecting: false,
          isConnected: true,
          errorMessage: null,
        );
        break;

      case WebSocketConnectionStatus.disconnected:
        state = state.copyWith(
          isConnecting: false,
          isConnected: false,
        );
        break;

      case WebSocketConnectionStatus.reconnecting:
        state = state.copyWith(
          isConnecting: true,
          isConnected: false,
        );
        break;

      case WebSocketConnectionStatus.error:
        state = state.copyWith(
          isConnecting: false,
          isConnected: false,
          errorMessage: event.message ?? 'Erreur de connexion',
        );
        break;
    }
  }

  /// Arrête le tracking
  Future<void> stopTracking() async {
    debugPrint('[TrackingProvider] Stopping tracking');

    _cancelSubscriptions();
    await _webSocketService.disconnect();

    state = state.reset();
  }

  /// Annule tous les abonnements
  void _cancelSubscriptions() {
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();

    _locationSubscription = null;
    _statusSubscription = null;
    _connectionSubscription = null;
  }

  /// Demande l'historique de tracking
  void requestTrackingHistory() {
    if (state.currentDeliveryId != null && state.isConnected) {
      _webSocketService.requestTrackingHistory();

      // Écouter la réponse
      _webSocketService.onTrackingHistory().listen((history) {
        debugPrint('[TrackingProvider] Received tracking history: ${history.length} points');
        state = state.copyWith(
          locationHistory: history,
        );
      });
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _webSocketService.dispose();
    super.dispose();
  }
}

/// Provider pour le service WebSocket
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final socketClient = ref.watch(socketClientProvider);
  return WebSocketService(socketClient);
});

/// Provider pour le tracking provider
final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return TrackingNotifier(webSocketService);
});
