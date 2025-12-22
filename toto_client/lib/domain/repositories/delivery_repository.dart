import '../entities/delivery.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Paramètres pour créer une livraison
class CreateDeliveryParams {
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? pickupPhone;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String deliveryPhone;
  final String receiverName;
  final String? packageDescription;
  final double? packageWeight;
  final String? specialInstructions;

  const CreateDeliveryParams({
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.pickupPhone,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryPhone,
    required this.receiverName,
    this.packageDescription,
    this.packageWeight,
    this.specialInstructions,
  });
}

/// Interface du repository de livraison
abstract class DeliveryRepository {
  Future<Result<Delivery>> createDelivery(CreateDeliveryParams params);
  Future<Result<List<Delivery>>> getDeliveries({DeliveryStatus? status});
  Future<Result<Delivery>> getDeliveryById(String id);
  Future<Result<Delivery>> cancelDelivery(String id);
  Future<Result<Delivery>> verifyQRCode({
    required String deliveryId,
    required String qrCode,
    required String type,
  });
}
