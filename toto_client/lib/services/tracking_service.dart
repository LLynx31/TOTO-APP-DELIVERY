import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import '../models/delivery_model.dart';
import 'api_client.dart';

class LocationUpdate {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationUpdate({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    return LocationUpdate(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class TrackingService {
  final _apiClient = ApiClient();
  io.Socket? _socket;

  final _deliveryUpdateController =
      StreamController<DeliveryModel>.broadcast();
  final _locationUpdateController =
      StreamController<LocationUpdate>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<DeliveryModel> get deliveryUpdates => _deliveryUpdateController.stream;
  Stream<LocationUpdate> get locationUpdates =>
      _locationUpdateController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // Initialiser la connexion Socket.io
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    // Récupérer le token d'accès
    final accessToken = await _apiClient.getRefreshToken();

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({
            'token': accessToken,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      _connectionController.add(false);
    });

    // Écouter les mises à jour de livraison
    _socket!.on('deliveryUpdate', (data) {
      try {
        final delivery = DeliveryModel.fromJson(data);
        _deliveryUpdateController.add(delivery);
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    });

    // Écouter les mises à jour de localisation
    _socket!.on('locationUpdate', (data) {
      try {
        final location = LocationUpdate.fromJson(data);
        _locationUpdateController.add(location);
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    });

    _socket!.connect();
  }

  // Suivre une livraison spécifique
  void trackDelivery(String deliveryId) {
    if (_socket == null || !_socket!.connected) {
      return;
    }

    _socket!.emit('trackDelivery', {'deliveryId': deliveryId});
  }

  // Arrêter de suivre une livraison
  void untrackDelivery(String deliveryId) {
    if (_socket == null || !_socket!.connected) {
      return;
    }

    _socket!.emit('untrackDelivery', {'deliveryId': deliveryId});
  }

  // Se déconnecter
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  // Nettoyer les ressources
  void dispose() {
    disconnect();
    _deliveryUpdateController.close();
    _locationUpdateController.close();
    _connectionController.close();
  }
}
