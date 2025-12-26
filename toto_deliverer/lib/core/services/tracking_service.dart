import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import 'api_client.dart';

/// Service pour gérer le tracking GPS en temps réel via WebSocket
///
/// Utilise Socket.io pour la communication bidirectionnelle
/// Authentification via JWT token
class TrackingService {
  io.Socket? _socket;
  final _apiClient = ApiClient();

  // Callbacks pour les événements de connexion
  Function()? _onConnected;
  Function()? _onDisconnected;
  Function(dynamic)? _onConnectError;

  /// Initialise la connexion WebSocket avec authentification JWT
  ///
  /// Récupère le token depuis ApiClient et configure les listeners
  /// Throws Exception si l'utilisateur n'est pas authentifié
  Future<void> connect() async {
    if (_socket?.connected == true) return;

    // Récupérer le token d'accès depuis ApiClient
    final accessToken = await _apiClient.getAccessToken();

    if (accessToken == null) {
      throw Exception('Impossible de se connecter au WebSocket: utilisateur non authentifié');
    }

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer $accessToken',
          })
          .build(),
    );

    // Configurer les listeners de connexion
    _socket!.onConnect((_) {
      _onConnected?.call();
    });

    _socket!.onDisconnect((_) {
      _onDisconnected?.call();
    });

    _socket!.onConnectError((data) {
      _onConnectError?.call(data);
    });

    _socket!.connect();
  }

  /// Configure le callback appelé lors de la connexion réussie
  void setOnConnected(Function() callback) {
    _onConnected = callback;
  }

  /// Configure le callback appelé lors de la déconnexion
  void setOnDisconnected(Function() callback) {
    _onDisconnected = callback;
  }

  /// Configure le callback appelé lors d'une erreur de connexion
  void setOnConnectError(Function(dynamic) callback) {
    _onConnectError = callback;
  }

  /// Déconnecte le WebSocket et libère les ressources
  void disconnect() {
    removeAllListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Rejoindre une room de livraison pour recevoir les updates
  ///
  /// Backend event: 'join-delivery'
  /// Permet au livreur de recevoir les updates de cette livraison
  void joinDeliveryRoom(String deliveryId) {
    _socket?.emit('join-delivery', {'deliveryId': deliveryId});
  }

  /// Quitter une room de livraison
  ///
  /// Backend event: 'leave-delivery'
  /// Arrête de recevoir les updates de cette livraison
  void leaveDeliveryRoom(String deliveryId) {
    _socket?.emit('leave-delivery', {'deliveryId': deliveryId});
  }

  /// Met à jour la position GPS du livreur en temps réel
  ///
  /// Backend event: 'update-location'
  /// Envoie les coordonnées GPS au backend pour tracking en temps réel
  /// Le client peut suivre la progression sur la carte
  void updateLocation(String deliveryId, double latitude, double longitude) {
    _socket?.emit('update-location', {
      'deliveryId': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Écoute les mises à jour de statut de livraison
  ///
  /// Backend event: 'status-updated'
  /// Reçoit: { deliveryId, status, updatedAt }
  void onStatusUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('status-updated', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  /// Écoute les mises à jour de position du livreur
  ///
  /// Backend event: 'location-updated'
  /// Reçoit: { deliveryId, latitude, longitude, timestamp }
  void onLocationUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('location-updated', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  /// Écoute les messages du client ou du système
  ///
  /// Backend event: 'message'
  /// Reçoit: { deliveryId, senderId, message, timestamp }
  void onMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('message', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  /// Écoute les erreurs WebSocket
  ///
  /// Backend event: 'error'
  void onError(Function(dynamic) callback) {
    _socket?.on('error', (data) {
      callback(data);
    });
  }

  /// Nettoie tous les listeners d'événements
  void removeAllListeners() {
    _socket?.off('status-updated');
    _socket?.off('location-updated');
    _socket?.off('message');
    _socket?.off('error');
  }

  /// Reconnecte le WebSocket si déconnecté
  ///
  /// Utile pour gérer les pertes de connexion réseau
  Future<void> reconnect() async {
    disconnect();
    await connect();
  }

  /// Vérifie si le WebSocket est connecté
  bool get isConnected => _socket?.connected ?? false;
}
