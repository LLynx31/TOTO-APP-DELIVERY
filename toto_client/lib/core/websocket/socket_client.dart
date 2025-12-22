import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import '../config/env_config.dart';

/// État de connexion WebSocket
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Client WebSocket pour le tracking en temps réel
class SocketClient {
  io.Socket? _socket;
  final FlutterSecureStorage _secureStorage;

  SocketConnectionState _connectionState = SocketConnectionState.disconnected;
  final _connectionStateController = StreamController<SocketConnectionState>.broadcast();

  final Map<String, List<Function(dynamic)>> _eventListeners = {};

  SocketClient({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// État de connexion actuel
  SocketConnectionState get connectionState => _connectionState;

  /// Stream de l'état de connexion
  Stream<SocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Vérifie si connecté
  bool get isConnected => _connectionState == SocketConnectionState.connected;

  /// Connexion au serveur WebSocket
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('[Socket] Already connected');
      return;
    }

    _updateState(SocketConnectionState.connecting);

    try {
      final token = await _secureStorage.read(key: ApiConfig.accessTokenKey);

      _socket = io.io(
        '${EnvConfig.socketUrl}${ApiConfig.trackingNamespace}',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      _setupEventHandlers();
      _socket!.connect();
    } catch (e) {
      debugPrint('[Socket] Connection error: $e');
      _updateState(SocketConnectionState.error);
    }
  }

  /// Configuration des handlers d'événements de base
  void _setupEventHandlers() {
    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected');
      _updateState(SocketConnectionState.connected);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
      _updateState(SocketConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      debugPrint('[Socket] Connect error: $error');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onError((error) {
      debugPrint('[Socket] Error: $error');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onReconnecting((_) {
      debugPrint('[Socket] Reconnecting...');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.onReconnect((_) {
      debugPrint('[Socket] Reconnected');
      _updateState(SocketConnectionState.connected);
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('[Socket] Reconnection failed');
      _updateState(SocketConnectionState.error);
    });
  }

  /// Mise à jour de l'état de connexion
  void _updateState(SocketConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// Déconnexion
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _eventListeners.clear();
    _updateState(SocketConnectionState.disconnected);
    debugPrint('[Socket] Disconnected and disposed');
  }

  /// Émettre un événement
  void emit(String event, [dynamic data]) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[Socket] Cannot emit - not connected');
      return;
    }

    debugPrint('[Socket] Emitting: $event');
    _socket!.emit(event, data);
  }

  /// Écouter un événement (retourne un Stream)
  Stream<dynamic> on(String event) {
    final controller = StreamController<dynamic>.broadcast();

    void handler(dynamic data) {
      debugPrint('[Socket] Received: $event');
      controller.add(data);
    }

    _socket?.on(event, handler);
    _eventListeners[event] ??= [];
    _eventListeners[event]!.add(handler);

    return controller.stream;
  }

  /// Écouter un événement une seule fois
  void once(String event, Function(dynamic) callback) {
    _socket?.once(event, callback);
  }

  /// Retirer l'écoute d'un événement
  void off(String event) {
    _socket?.off(event);
    _eventListeners.remove(event);
  }

  // ============================================
  // Méthodes spécifiques au tracking de livraison
  // ============================================

  /// Rejoindre la room de tracking d'une livraison
  void joinDeliveryRoom(String deliveryId) {
    emit('join_delivery', {'delivery_id': deliveryId});
    debugPrint('[Socket] Joining delivery room: $deliveryId');
  }

  /// Quitter la room de tracking d'une livraison
  void leaveDeliveryRoom(String deliveryId) {
    emit('leave_delivery', {'delivery_id': deliveryId});
    debugPrint('[Socket] Leaving delivery room: $deliveryId');
  }

  /// Écouter les mises à jour de localisation
  Stream<LocationUpdate> onLocationUpdated() {
    return on('location_updated').map((data) => LocationUpdate.fromJson(data));
  }

  /// Écouter les changements de statut
  Stream<StatusUpdate> onStatusChanged() {
    return on('delivery_status_changed').map((data) => StatusUpdate.fromJson(data));
  }

  /// Demander l'historique de tracking
  void getTrackingHistory(String deliveryId) {
    emit('get_tracking_history', {'delivery_id': deliveryId});
  }

  /// Écouter la réponse de l'historique
  Stream<TrackingHistory> onTrackingHistory() {
    return on('tracking_history').map((data) => TrackingHistory.fromJson(data));
  }

  /// Libérer les ressources
  void dispose() {
    disconnect();
    _connectionStateController.close();
  }
}

/// Modèle pour les mises à jour de localisation
class LocationUpdate {
  final String deliveryId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;

  LocationUpdate({
    required this.deliveryId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    return LocationUpdate(
      deliveryId: json['delivery_id'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Modèle pour les changements de statut
class StatusUpdate {
  final String deliveryId;
  final String status;
  final Map<String, dynamic>? data;

  StatusUpdate({
    required this.deliveryId,
    required this.status,
    this.data,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      deliveryId: json['delivery_id'] ?? '',
      status: json['status'] ?? '',
      data: json,
    );
  }
}

/// Modèle pour l'historique de tracking
class TrackingHistory {
  final String deliveryId;
  final List<LocationUpdate> history;

  TrackingHistory({
    required this.deliveryId,
    required this.history,
  });

  factory TrackingHistory.fromJson(Map<String, dynamic> json) {
    final historyList = (json['history'] as List?)
        ?.map((item) => LocationUpdate.fromJson(item))
        .toList() ?? [];

    return TrackingHistory(
      deliveryId: json['delivery_id'] ?? '',
      history: historyList,
    );
  }
}
