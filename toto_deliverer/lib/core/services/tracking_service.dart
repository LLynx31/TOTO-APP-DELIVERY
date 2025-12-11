import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import 'api_client.dart';

class TrackingService {
  io.Socket? _socket;
  final _apiClient = ApiClient();

  // Initialiser la connexion WebSocket
  Future<void> connect() async {
    if (_socket?.connected == true) return;

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer ${_apiClient.isAuthenticated}',
          })
          .build(),
    );

    _socket!.connect();
  }

  // Déconnecter
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // Rejoindre une room de livraison
  void joinDeliveryRoom(String deliveryId) {
    _socket?.emit('join-delivery', {'deliveryId': deliveryId});
  }

  // Quitter une room de livraison
  void leaveDeliveryRoom(String deliveryId) {
    _socket?.emit('leave-delivery', {'deliveryId': deliveryId});
  }

  // Mettre à jour la position en temps réel
  void updateLocation(String deliveryId, double latitude, double longitude) {
    _socket?.emit('update-location', {
      'deliveryId': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // Écouter les mises à jour de statut
  void onStatusUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('status-updated', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Écouter les messages
  void onMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('message', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Écouter les erreurs
  void onError(Function(dynamic) callback) {
    _socket?.on('error', (data) {
      callback(data);
    });
  }

  // Nettoyer les listeners
  void removeAllListeners() {
    _socket?.off('status-updated');
    _socket?.off('message');
    _socket?.off('error');
  }

  // Vérifier si connecté
  bool get isConnected => _socket?.connected ?? false;
}
