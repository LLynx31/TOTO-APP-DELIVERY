import '../../domain/entities/delivery.dart';

/// Model pour les mises à jour de localisation en temps réel
class LocationUpdate {
  final String deliveryId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? heading; // Direction en degrés
  final double? speed; // Vitesse en m/s

  const LocationUpdate({
    required this.deliveryId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.heading,
    this.speed,
  });

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    return LocationUpdate(
      deliveryId: json['deliveryId'] as String? ?? json['delivery_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryId': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
    };
  }

  @override
  String toString() {
    return 'LocationUpdate(deliveryId: $deliveryId, lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}

/// Model pour les mises à jour de statut de livraison
class DeliveryStatusUpdate {
  final String deliveryId;
  final DeliveryStatus newStatus;
  final DeliveryStatus? previousStatus;
  final DateTime timestamp;
  final String? message; // Message optionnel (ex: "Colis récupéré")
  final Map<String, dynamic>? metadata; // Données additionnelles

  const DeliveryStatusUpdate({
    required this.deliveryId,
    required this.newStatus,
    this.previousStatus,
    required this.timestamp,
    this.message,
    this.metadata,
  });

  factory DeliveryStatusUpdate.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusUpdate(
      deliveryId: json['deliveryId'] as String? ?? json['delivery_id'] as String,
      newStatus: _parseDeliveryStatus(json['newStatus'] ?? json['new_status']),
      previousStatus: json['previousStatus'] != null || json['previous_status'] != null
          ? _parseDeliveryStatus(json['previousStatus'] ?? json['previous_status'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      message: json['message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static DeliveryStatus _parseDeliveryStatus(dynamic status) {
    if (status is DeliveryStatus) return status;

    final statusStr = status.toString().toUpperCase();
    return DeliveryStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == statusStr,
      orElse: () => DeliveryStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryId': deliveryId,
      'newStatus': newStatus.name,
      if (previousStatus != null) 'previousStatus': previousStatus!.name,
      'timestamp': timestamp.toIso8601String(),
      if (message != null) 'message': message,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'DeliveryStatusUpdate(deliveryId: $deliveryId, status: $newStatus, time: $timestamp)';
  }
}

/// Model pour les événements de connexion WebSocket
enum WebSocketConnectionStatus {
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

class WebSocketConnectionEvent {
  final WebSocketConnectionStatus status;
  final String? message;
  final DateTime timestamp;

  const WebSocketConnectionEvent({
    required this.status,
    this.message,
    required this.timestamp,
  });

  factory WebSocketConnectionEvent.connecting() {
    return WebSocketConnectionEvent(
      status: WebSocketConnectionStatus.connecting,
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketConnectionEvent.connected() {
    return WebSocketConnectionEvent(
      status: WebSocketConnectionStatus.connected,
      message: 'Connecté au serveur',
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketConnectionEvent.disconnected([String? reason]) {
    return WebSocketConnectionEvent(
      status: WebSocketConnectionStatus.disconnected,
      message: reason ?? 'Déconnecté du serveur',
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketConnectionEvent.reconnecting() {
    return WebSocketConnectionEvent(
      status: WebSocketConnectionStatus.reconnecting,
      message: 'Reconnexion en cours...',
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketConnectionEvent.error(String error) {
    return WebSocketConnectionEvent(
      status: WebSocketConnectionStatus.error,
      message: error,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'WebSocketConnectionEvent(status: $status, message: $message, time: $timestamp)';
  }
}
