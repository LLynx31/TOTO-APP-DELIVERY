import '../../shared/models/delivery_model.dart';
import '../adapters/delivery_adapter.dart';
import '../config/api_config.dart';
import 'api_client.dart';

/// Service pour gérer les livraisons avec intégration backend
///
/// Utilise DeliveryAdapter pour transformer les réponses backend
class DeliveryService {
  final _apiClient = ApiClient();

  /// Récupère les livraisons disponibles (statut: pending)
  ///
  /// Backend: GET /deliveries/available
  Future<List<DeliveryModel>> getAvailableDeliveries() async {
    final response = await _apiClient.get(ApiConfig.deliveriesAvailable);

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => DeliveryAdapter.fromBackend(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les livraisons actives du livreur
  ///
  /// Backend: GET /deliveries (puis filtrage côté client)
  /// Statuts actifs: accepted, pickupInProgress, pickedUp, deliveryInProgress
  Future<List<DeliveryModel>> getActiveDeliveries() async {
    final response = await _apiClient.get(ApiConfig.deliveriesActive);

    final List<dynamic> data = response.data as List<dynamic>;
    final allDeliveries = data
        .map((json) => DeliveryAdapter.fromBackend(json as Map<String, dynamic>))
        .toList();

    // Filtrer côté client pour les statuts actifs
    return allDeliveries.where(DeliveryAdapter.isActive).toList();
  }

  /// Récupère les livraisons complétées (statut: delivered)
  ///
  /// Backend: GET /deliveries?status=delivered
  Future<List<DeliveryModel>> getCompletedDeliveries() async {
    final response = await _apiClient.get(
      ApiConfig.deliveriesCompleted,
      queryParameters: {'status': 'delivered'},
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => DeliveryAdapter.fromBackend(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère une livraison par ID
  ///
  /// Backend: GET /deliveries/:id
  Future<DeliveryModel> getDeliveryById(String id) async {
    final response = await _apiClient.get(ApiConfig.deliveryById(id));
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Accepte une livraison
  ///
  /// Backend: POST /deliveries/:id/accept
  /// Consomme 1 quota du livreur
  Future<DeliveryModel> acceptDelivery(String deliveryId) async {
    final response = await _apiClient.post(
      ApiConfig.deliveryAccept(deliveryId),
    );
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Démarre la phase de pickup (en route vers point A)
  ///
  /// Backend: PATCH /deliveries/:id avec status='pickupInProgress'
  Future<DeliveryModel> startPickup(String deliveryId) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryUpdate(deliveryId),
      data: {'status': 'pickupInProgress'},
    );
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Confirme le pickup avec scan QR code au point A
  ///
  /// Backend: POST /deliveries/:id/verify-qr avec type='pickup'
  /// Change le statut vers 'pickedUp'
  Future<DeliveryModel> confirmPickup(
    String deliveryId,
    String qrCode,
  ) async {
    final response = await _apiClient.post(
      ApiConfig.deliveryVerifyQR(deliveryId),
      data: {
        'qr_code': qrCode,
        'type': 'pickup',
      },
    );
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Démarre la phase de livraison (en route vers point B)
  ///
  /// Backend: PATCH /deliveries/:id avec status='deliveryInProgress'
  Future<DeliveryModel> startDelivery(String deliveryId) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryUpdate(deliveryId),
      data: {'status': 'deliveryInProgress'},
    );
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Confirme la livraison avec scan QR code au point B
  ///
  /// Backend: POST /deliveries/:id/verify-qr avec type='delivery'
  /// Change le statut vers 'delivered'
  ///
  /// Alternative: Si le destinataire n'a pas l'app, utiliser confirmDeliveryWithCode()
  Future<DeliveryModel> confirmDelivery(
    String deliveryId,
    String qrCode,
  ) async {
    final response = await _apiClient.post(
      ApiConfig.deliveryVerifyQR(deliveryId),
      data: {
        'qr_code': qrCode,
        'type': 'delivery',
      },
    );
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Confirme la livraison avec code 4 chiffres (fallback si pas d'app)
  ///
  /// Backend: POST /deliveries/:id/verify-qr avec delivery_code
  Future<DeliveryModel> confirmDeliveryWithCode(
    String deliveryId,
    String code,
  ) async {
    final response = await _apiClient.post(
      ApiConfig.deliveryVerifyQR(deliveryId),
      data: {
        'delivery_code': code,
        'type': 'delivery',
      },
    );
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Annule une livraison avec raison
  ///
  /// Backend: POST /deliveries/:id/cancel
  /// Rembourse le quota au client
  Future<DeliveryModel> cancelDelivery(
    String deliveryId,
    String reason,
  ) async {
    final response = await _apiClient.post(
      ApiConfig.deliveryCancel(deliveryId),
      data: {'reason': reason},
    );
    return DeliveryAdapter.fromBackend(response.data as Map<String, dynamic>);
  }

  /// Note le client après livraison (rating bidirectionnel)
  ///
  /// Backend: POST /deliveries/:id/rate
  /// Le client peut aussi noter le livreur sur le même endpoint
  Future<void> rateCustomer(
    String deliveryId,
    int rating,
    String? comment,
  ) async {
    await _apiClient.post(
      ApiConfig.rateDelivery(deliveryId),
      data: {
        'stars': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }

  /// Récupère la notation donnée pour une livraison
  ///
  /// Backend: GET /deliveries/:id/rating
  /// Retourne null si pas encore noté
  Future<Map<String, dynamic>?> getDeliveryRating(String deliveryId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.getDeliveryRating(deliveryId),
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si le livreur a déjà noté cette livraison
  ///
  /// Backend: GET /deliveries/:id/has-rated
  Future<bool> hasRatedDelivery(String deliveryId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.checkHasRated(deliveryId),
      );
      final data = response.data as Map<String, dynamic>;
      return data['hasRated'] ?? false; // Note: backend retourne camelCase après transformation
    } catch (e) {
      return false;
    }
  }

  /// Signale un problème pendant la livraison
  ///
  /// Backend: POST /deliveries/:id/problem
  ///
  /// Types de problèmes:
  /// - 'address_incorrect' - Adresse incorrecte
  /// - 'recipient_absent' - Destinataire absent
  /// - 'package_damaged' - Colis endommagé
  /// - 'access_denied' - Accès refusé
  /// - 'other' - Autre problème
  Future<void> reportProblem(
    String deliveryId,
    String type,
    String description,
  ) async {
    await _apiClient.post(
      ApiConfig.deliveryProblem(deliveryId),
      data: {
        'type': type,
        'description': description,
      },
    );
  }

  /// Récupère les QR codes d'une livraison
  ///
  /// Backend: GET /deliveries/:id/qr-codes
  /// Retourne: { qr_code_pickup, qr_code_delivery, delivery_code }
  Future<Map<String, dynamic>> getQRCodes(String deliveryId) async {
    final response = await _apiClient.get(
      ApiConfig.deliveryQRCodes(deliveryId),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Met à jour la position GPS du livreur
  ///
  /// Backend: POST /deliveries/:id/tracking
  /// Note: Préférer utiliser le WebSocket pour le tracking temps réel
  Future<void> updateTracking(
    String deliveryId,
    double latitude,
    double longitude,
  ) async {
    await _apiClient.post(
      ApiConfig.deliveryTracking(deliveryId),
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }
}
