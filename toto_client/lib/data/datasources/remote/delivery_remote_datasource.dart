import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../models/delivery/create_delivery_dto.dart';
import '../../models/delivery/delivery_dto.dart';

/// Interface pour la source de données distante de livraison
abstract class DeliveryRemoteDatasource {
  Future<DeliveryDto> createDelivery(CreateDeliveryDto request);
  Future<List<DeliveryDto>> getDeliveries({String? status});
  Future<DeliveryDto> getDeliveryById(String id);
  Future<DeliveryDto> cancelDelivery(String id);
  Future<DeliveryDto> verifyQRCode({
    required String deliveryId,
    required String qrCode,
    required String type,
  });
}

/// Implémentation de la source de données distante de livraison
class DeliveryRemoteDatasourceImpl implements DeliveryRemoteDatasource {
  final DioClient dioClient;

  DeliveryRemoteDatasourceImpl(this.dioClient);

  @override
  Future<DeliveryDto> createDelivery(CreateDeliveryDto request) async {
    final response = await dioClient.post(
      ApiConfig.deliveries,
      data: request.toJson(),
    );

    return DeliveryDto.fromJson(response.data);
  }

  @override
  Future<List<DeliveryDto>> getDeliveries({String? status}) async {
    final response = await dioClient.get(
      ApiConfig.deliveries,
      queryParameters: status != null ? {'status': status} : null,
    );

    final List<dynamic> data = response.data as List;
    return data.map((json) => DeliveryDto.fromJson(json)).toList();
  }

  @override
  Future<DeliveryDto> getDeliveryById(String id) async {
    final response = await dioClient.get(
      ApiConfig.deliveryById(id),
    );

    return DeliveryDto.fromJson(response.data);
  }

  @override
  Future<DeliveryDto> cancelDelivery(String id) async {
    final response = await dioClient.post(
      ApiConfig.cancelDelivery(id),
    );

    return DeliveryDto.fromJson(response.data);
  }

  @override
  Future<DeliveryDto> verifyQRCode({
    required String deliveryId,
    required String qrCode,
    required String type,
  }) async {
    final response = await dioClient.post(
      ApiConfig.verifyQR(deliveryId),
      data: {
        'qr_code': qrCode,
        'type': type,
      },
    );

    return DeliveryDto.fromJson(response.data['delivery']);
  }
}
