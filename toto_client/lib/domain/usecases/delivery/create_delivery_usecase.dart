import '../../entities/delivery.dart';
import '../../repositories/delivery_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour créer une livraison
class CreateDeliveryUsecase {
  final DeliveryRepository repository;

  CreateDeliveryUsecase(this.repository);

  Future<Result<Delivery>> call(CreateDeliveryParams params) async {
    // Validation métier
    if (params.pickupLatitude == params.deliveryLatitude &&
        params.pickupLongitude == params.deliveryLongitude) {
      return const Failure(
        'Les adresses d\'enlèvement et de livraison doivent être différentes',
      );
    }

    // Appel au repository
    return await repository.createDelivery(params);
  }
}
