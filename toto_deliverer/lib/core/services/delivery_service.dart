import '../config/api_config.dart';
import 'api_client.dart';

class DeliveryService {
  final _apiClient = ApiClient();

  // Récupérer les livraisons disponibles
  Future<List<dynamic>> getAvailableDeliveries() async {
    final response = await _apiClient.get(ApiConfig.deliveriesAvailable);
    return response.data as List<dynamic>;
  }

  // Récupérer les livraisons actives
  Future<List<dynamic>> getActiveDeliveries() async {
    final response = await _apiClient.get(ApiConfig.deliveriesActive);
    return response.data as List<dynamic>;
  }

  // Récupérer les livraisons complétées
  Future<List<dynamic>> getCompletedDeliveries() async {
    final response = await _apiClient.get(ApiConfig.deliveriesCompleted);
    return response.data as List<dynamic>;
  }

  // Récupérer une livraison par ID
  Future<Map<String, dynamic>> getDeliveryById(String id) async {
    final response = await _apiClient.get(ApiConfig.deliveryById(id));
    return response.data as Map<String, dynamic>;
  }

  // Accepter une livraison
  Future<Map<String, dynamic>> acceptDelivery(String deliveryId) async {
    final response = await _apiClient.post(
      ApiConfig.deliveryAccept(deliveryId),
    );
    return response.data as Map<String, dynamic>;
  }

  // Démarrer le pickup
  Future<Map<String, dynamic>> startPickup(String deliveryId) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryStartPickup(deliveryId),
    );
    return response.data as Map<String, dynamic>;
  }

  // Confirmer le pickup avec QR code
  Future<Map<String, dynamic>> confirmPickup(
    String deliveryId,
    String qrCode,
  ) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryConfirmPickup(deliveryId),
      data: {'qr_code': qrCode},
    );
    return response.data as Map<String, dynamic>;
  }

  // Démarrer la livraison
  Future<Map<String, dynamic>> startDelivery(String deliveryId) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryStartDelivery(deliveryId),
    );
    return response.data as Map<String, dynamic>;
  }

  // Confirmer la livraison avec QR code
  Future<Map<String, dynamic>> confirmDelivery(
    String deliveryId,
    String qrCode,
  ) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryConfirmDelivery(deliveryId),
      data: {'qr_code': qrCode},
    );
    return response.data as Map<String, dynamic>;
  }

  // Annuler une livraison
  Future<Map<String, dynamic>> cancelDelivery(
    String deliveryId,
    String reason,
  ) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryCancel(deliveryId),
      data: {'reason': reason},
    );
    return response.data as Map<String, dynamic>;
  }

  // Noter le client
  Future<void> rateCustomer(
    String deliveryId,
    int rating,
    String? comment,
  ) async {
    await _apiClient.post(
      ApiConfig.deliveryRating(deliveryId),
      data: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );
  }

  // Signaler un problème
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

  // Récupérer les QR codes
  Future<Map<String, dynamic>> getQRCodes(String deliveryId) async {
    final response = await _apiClient.get(
      ApiConfig.deliveryQRCodes(deliveryId),
    );
    return response.data as Map<String, dynamic>;
  }

  // Mettre à jour la position en temps réel
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
