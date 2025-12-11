import '../config/api_config.dart';
import '../models/delivery_model.dart';
import 'api_client.dart';

class CreateDeliveryRequest {
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? pickupPhone;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String deliveryPhone;
  final String receiverName;
  final String packageDescription;
  final double? packageWeight;
  final String? specialInstructions;

  CreateDeliveryRequest({
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.pickupPhone,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryPhone,
    required this.receiverName,
    required this.packageDescription,
    this.packageWeight,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      if (pickupPhone != null) 'pickup_phone': pickupPhone,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_phone': deliveryPhone,
      'receiver_name': receiverName,
      'package_description': packageDescription,
      if (packageWeight != null) 'package_weight': packageWeight,
      if (specialInstructions != null)
        'special_instructions': specialInstructions,
    };
  }
}

class DeliveryService {
  final _apiClient = ApiClient();

  // Créer une nouvelle livraison
  Future<DeliveryModel> createDelivery(CreateDeliveryRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.deliveries,
      data: request.toJson(),
    );

    return DeliveryModel.fromJson(response.data);
  }

  // Récupérer toutes les livraisons du client
  Future<List<DeliveryModel>> getMyDeliveries({
    DeliveryStatus? status,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) {
      queryParams['status'] = _statusToString(status);
    }
    if (limit != null) {
      queryParams['limit'] = limit;
    }
    if (offset != null) {
      queryParams['offset'] = offset;
    }

    final response = await _apiClient.get(
      ApiConfig.deliveries,
      queryParameters: queryParams,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => DeliveryModel.fromJson(json)).toList();
  }

  // Récupérer une livraison par ID
  Future<DeliveryModel> getDeliveryById(String id) async {
    final response = await _apiClient.get(
      ApiConfig.deliveryById(id),
    );

    return DeliveryModel.fromJson(response.data);
  }

  // Annuler une livraison
  Future<DeliveryModel> cancelDelivery(String id) async {
    final response = await _apiClient.patch(
      ApiConfig.deliveryCancel(id),
    );

    return DeliveryModel.fromJson(response.data);
  }

  // Vérifier un code QR
  Future<Map<String, dynamic>> verifyQRCode({
    required String deliveryId,
    required String qrCode,
    required String type, // 'pickup' ou 'delivery'
  }) async {
    final response = await _apiClient.post(
      ApiConfig.deliveryVerifyQR(deliveryId),
      data: {
        'qr_code': qrCode,
        'type': type,
      },
    );

    return response.data;
  }

  // Helper pour convertir le statut en string
  String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.accepted:
        return 'accepted';
      case DeliveryStatus.pickupInProgress:
        return 'pickup_in_progress';
      case DeliveryStatus.pickedUp:
        return 'picked_up';
      case DeliveryStatus.deliveryInProgress:
        return 'delivery_in_progress';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }
}
