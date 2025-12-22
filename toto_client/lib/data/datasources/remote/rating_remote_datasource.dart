import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';

/// Remote datasource interface pour les ratings
abstract class RatingRemoteDatasource {
  Future<dynamic> createRating(String deliveryId, Map<String, dynamic> data);
  Future<dynamic> getRatingForDelivery(String deliveryId);
  Future<bool> hasRated(String deliveryId);
}

/// Implémentation du remote datasource pour les ratings
class RatingRemoteDatasourceImpl implements RatingRemoteDatasource {
  final DioClient dioClient;

  RatingRemoteDatasourceImpl(this.dioClient);

  @override
  Future<dynamic> createRating(String deliveryId, Map<String, dynamic> data) async {
    final response = await dioClient.post(
      ApiConfig.rateDelivery(deliveryId),
      data: data,
    );
    return response.data;
  }

  @override
  Future<dynamic> getRatingForDelivery(String deliveryId) async {
    final response = await dioClient.get(
      ApiConfig.getDeliveryRating(deliveryId),
    );
    return response.data;
  }

  @override
  Future<bool> hasRated(String deliveryId) async {
    try {
      final response = await dioClient.get(
        ApiConfig.checkHasRated(deliveryId),
      );
      return response.data['has_rated'] as bool? ?? false;
    } catch (e) {
      // Si erreur (404 par exemple), considérer que l'utilisateur n'a pas noté
      return false;
    }
  }
}
