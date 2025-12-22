import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service de tracking de localisation en temps réel
/// Envoie périodiquement la position GPS du livreur au serveur
class LocationTrackingService {
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  // Configuration
  static const Duration updateInterval = Duration(seconds: 8);
  static const double minimumDistanceMeters = 10.0; // Distance minimale pour envoyer un update

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Position? get lastPosition => _lastPosition;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Callback appelé quand une nouvelle position est disponible
  Function(double latitude, double longitude, double? speed, double? heading)? onLocationUpdate;

  /// Démarre le tracking de position
  /// [deliveryId] - ID de la livraison en cours
  /// [onUpdate] - Callback appelé à chaque update de position
  Future<bool> startTracking({
    required Function(double lat, double lng, double? speed, double? heading) onUpdate,
  }) async {
    if (_isTracking) {
      debugPrint('[LocationTracking] Already tracking');
      return true;
    }

    debugPrint('[LocationTracking] Starting location tracking');

    // Vérifier et demander les permissions
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      debugPrint('[LocationTracking] Location permission denied');
      return false;
    }

    // Vérifier si le GPS est activé
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationTracking] Location service disabled');
      return false;
    }

    onLocationUpdate = onUpdate;
    _isTracking = true;

    // Obtenir la position initiale
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Envoyer immédiatement la première position
      if (_lastPosition != null) {
        _sendLocationUpdate(_lastPosition!);
      }
    } catch (e) {
      debugPrint('[LocationTracking] Failed to get initial position: $e');
    }

    // Démarrer le timer pour des updates périodiques
    _startPeriodicUpdates();

    debugPrint('[LocationTracking] Location tracking started successfully');
    return true;
  }

  /// Démarre les mises à jour périodiques de position
  void _startPeriodicUpdates() {
    _locationTimer = Timer.periodic(updateInterval, (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Vérifier si la position a suffisamment changé
        if (_shouldSendUpdate(position)) {
          _sendLocationUpdate(position);
          _lastPosition = position;
        }
      } catch (e) {
        debugPrint('[LocationTracking] Failed to get position: $e');
      }
    });
  }

  /// Vérifie si on doit envoyer un update (distance minimale ou temps écoulé)
  bool _shouldSendUpdate(Position newPosition) {
    if (_lastPosition == null) return true;

    // Calculer la distance depuis la dernière position
    final distanceInMeters = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // Envoyer si la distance est supérieure au seuil
    return distanceInMeters >= minimumDistanceMeters;
  }

  /// Envoie un update de position
  void _sendLocationUpdate(Position position) {
    _lastUpdateTime = DateTime.now();

    debugPrint(
      '[LocationTracking] Sending update: lat=${position.latitude.toStringAsFixed(6)}, '
      'lng=${position.longitude.toStringAsFixed(6)}, '
      'speed=${position.speed.toStringAsFixed(2)} m/s',
    );

    onLocationUpdate?.call(
      position.latitude,
      position.longitude,
      position.speed,
      position.heading,
    );
  }

  /// Arrête le tracking de position
  void stopTracking() {
    if (!_isTracking) return;

    debugPrint('[LocationTracking] Stopping location tracking');

    _locationTimer?.cancel();
    _locationTimer = null;
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    onLocationUpdate = null;

    debugPrint('[LocationTracking] Location tracking stopped');
  }

  /// Envoie manuellement la position actuelle
  Future<bool> sendCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _sendLocationUpdate(position);
      _lastPosition = position;
      return true;
    } catch (e) {
      debugPrint('[LocationTracking] Failed to send current position: $e');
      return false;
    }
  }

  /// Vérifie et demande les permissions de localisation
  Future<bool> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Les permissions sont refusées de façon permanente
      debugPrint('[LocationTracking] Location permissions are permanently denied');
      return false;
    }

    // Permission accordée (always ou whileInUse)
    return true;
  }

  /// Obtient le statut actuel des permissions
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Ouvre les paramètres de l'application pour gérer les permissions
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Ouvre les paramètres de l'application
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Vérifie si le service de localisation est activé
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Libère les ressources
  void dispose() {
    stopTracking();
  }
}
