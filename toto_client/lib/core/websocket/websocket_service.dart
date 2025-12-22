import 'dart:async';
import 'package:flutter/foundation.dart';
import 'socket_client.dart' as socket;
import 'websocket_models.dart';
import '../../domain/entities/delivery.dart';

/// Service WebSocket pour le tracking en temps réel des livraisons
/// Wrapper autour de SocketClient avec une API typée et simplifiée
class WebSocketService {
  final socket.SocketClient _socketClient;

  String? _currentDeliveryId;

  // Stream controllers
  final _locationUpdateController = StreamController<LocationUpdate>.broadcast();
  final _statusUpdateController = StreamController<DeliveryStatusUpdate>.broadcast();
  final _connectionEventController = StreamController<WebSocketConnectionEvent>.broadcast();

  // Subscriptions aux événements socket
  StreamSubscription<socket.LocationUpdate>? _locationSubscription;
  StreamSubscription<socket.StatusUpdate>? _statusSubscription;
  StreamSubscription<socket.SocketConnectionState>? _connectionSubscription;

  WebSocketService(this._socketClient) {
    _setupConnectionListener();
  }

  /// Streams publics
  Stream<LocationUpdate> get locationStream => _locationUpdateController.stream;
  Stream<DeliveryStatusUpdate> get statusStream => _statusUpdateController.stream;
  Stream<WebSocketConnectionEvent> get connectionStream => _connectionEventController.stream;

  /// État de connexion actuel
  bool get isConnected => _socketClient.isConnected;

  /// ID de la livraison en cours de tracking
  String? get currentDeliveryId => _currentDeliveryId;

  /// Configure l'écoute de l'état de connexion
  void _setupConnectionListener() {
    _connectionSubscription = _socketClient.connectionStateStream.listen(
      (state) {
        final event = _mapConnectionState(state);
        _connectionEventController.add(event);
        debugPrint('[WebSocketService] Connection state: ${state.name}');
      },
      onError: (error) {
        debugPrint('[WebSocketService] Connection error: $error');
        _connectionEventController.add(
          WebSocketConnectionEvent.error(error.toString()),
        );
      },
    );
  }

  /// Mappe l'état de connexion du SocketClient vers WebSocketConnectionEvent
  WebSocketConnectionEvent _mapConnectionState(socket.SocketConnectionState state) {
    switch (state) {
      case socket.SocketConnectionState.connecting:
        return WebSocketConnectionEvent.connecting();
      case socket.SocketConnectionState.connected:
        return WebSocketConnectionEvent.connected();
      case socket.SocketConnectionState.disconnected:
        return WebSocketConnectionEvent.disconnected();
      case socket.SocketConnectionState.reconnecting:
        return WebSocketConnectionEvent.reconnecting();
      case socket.SocketConnectionState.error:
        return WebSocketConnectionEvent.error('Erreur de connexion');
    }
  }

  /// Se connecte au serveur WebSocket et commence le tracking d'une livraison
  Future<void> connect({
    required String deliveryId,
  }) async {
    debugPrint('[WebSocketService] Connecting for delivery: $deliveryId');

    try {
      // Si déjà connecté à une autre livraison, déconnecter d'abord
      if (_currentDeliveryId != null && _currentDeliveryId != deliveryId) {
        await _leaveCurrentDelivery();
      }

      // Connexion au serveur WebSocket
      await _socketClient.connect();

      // Attendre la connexion (max 5 secondes)
      await _waitForConnection();

      // Rejoindre la room de la livraison
      _socketClient.joinDeliveryRoom(deliveryId);
      _currentDeliveryId = deliveryId;

      // S'abonner aux événements
      _subscribeToEvents();

      debugPrint('[WebSocketService] Successfully connected to delivery: $deliveryId');
    } catch (e) {
      debugPrint('[WebSocketService] Connection failed: $e');
      _connectionEventController.add(
        WebSocketConnectionEvent.error('Échec de la connexion: $e'),
      );
      rethrow;
    }
  }

  /// Attend que la connexion soit établie
  Future<void> _waitForConnection() async {
    if (_socketClient.isConnected) return;

    final completer = Completer<void>();
    Timer? timeoutTimer;
    StreamSubscription? subscription;

    timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError('Timeout de connexion');
      }
    });

    subscription = _socketClient.connectionStateStream.listen((state) {
      if (state == socket.SocketConnectionState.connected) {
        timeoutTimer?.cancel();
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else if (state == socket.SocketConnectionState.error) {
        timeoutTimer?.cancel();
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.completeError('Erreur de connexion');
        }
      }
    });

    return completer.future;
  }

  /// S'abonne aux événements de tracking
  void _subscribeToEvents() {
    // Annuler les abonnements précédents
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();

    // S'abonner aux mises à jour de localisation
    _locationSubscription = _socketClient.onLocationUpdated().listen(
      (update) {
        // Convertir vers notre modèle typé
        final typedUpdate = LocationUpdate(
          deliveryId: update.deliveryId,
          latitude: update.latitude,
          longitude: update.longitude,
          timestamp: update.timestamp,
          heading: update.heading,
          speed: update.speed,
        );
        _locationUpdateController.add(typedUpdate);
        debugPrint('[WebSocketService] Location update: ${update.latitude}, ${update.longitude}');
      },
      onError: (error) {
        debugPrint('[WebSocketService] Location stream error: $error');
      },
    );

    // S'abonner aux changements de statut
    _statusSubscription = _socketClient.onStatusChanged().listen(
      (update) {
        // Convertir le statut string vers DeliveryStatus enum
        final status = _parseDeliveryStatus(update.status);
        final typedUpdate = DeliveryStatusUpdate(
          deliveryId: update.deliveryId,
          newStatus: status,
          timestamp: DateTime.now(),
          metadata: update.data,
        );
        _statusUpdateController.add(typedUpdate);
        debugPrint('[WebSocketService] Status update: ${update.status}');
      },
      onError: (error) {
        debugPrint('[WebSocketService] Status stream error: $error');
      },
    );
  }

  /// Parse un statut string vers l'enum DeliveryStatus
  DeliveryStatus _parseDeliveryStatus(String status) {
    final statusUpper = status.toUpperCase();
    try {
      return DeliveryStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == statusUpper,
        orElse: () => DeliveryStatus.pending,
      );
    } catch (e) {
      debugPrint('[WebSocketService] Unknown status: $status, defaulting to pending');
      return DeliveryStatus.pending;
    }
  }

  /// Quitte la livraison en cours de tracking
  Future<void> _leaveCurrentDelivery() async {
    if (_currentDeliveryId != null) {
      debugPrint('[WebSocketService] Leaving delivery: $_currentDeliveryId');
      _socketClient.leaveDeliveryRoom(_currentDeliveryId!);
      _currentDeliveryId = null;

      // Annuler les abonnements
      await _locationSubscription?.cancel();
      await _statusSubscription?.cancel();
    }
  }

  /// Déconnecte du WebSocket et arrête le tracking
  Future<void> disconnect() async {
    debugPrint('[WebSocketService] Disconnecting');

    await _leaveCurrentDelivery();
    _socketClient.disconnect();

    debugPrint('[WebSocketService] Disconnected');
  }

  /// Demande l'historique de tracking pour la livraison en cours
  void requestTrackingHistory() {
    if (_currentDeliveryId != null) {
      _socketClient.getTrackingHistory(_currentDeliveryId!);
    } else {
      debugPrint('[WebSocketService] Cannot request history: no active delivery');
    }
  }

  /// Écoute l'historique de tracking (à appeler après requestTrackingHistory)
  Stream<List<LocationUpdate>> onTrackingHistory() {
    return _socketClient.onTrackingHistory().map((history) {
      return history.history.map((update) {
        return LocationUpdate(
          deliveryId: update.deliveryId,
          latitude: update.latitude,
          longitude: update.longitude,
          timestamp: update.timestamp,
          heading: update.heading,
          speed: update.speed,
        );
      }).toList();
    });
  }

  /// Libère toutes les ressources
  void dispose() {
    debugPrint('[WebSocketService] Disposing');

    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();

    _locationUpdateController.close();
    _statusUpdateController.close();
    _connectionEventController.close();

    _socketClient.dispose();

    debugPrint('[WebSocketService] Disposed');
  }
}
