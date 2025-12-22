import '../../entities/delivery.dart';
import '../../repositories/delivery_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour récupérer les livraisons
class GetDeliveriesUsecase {
  final DeliveryRepository repository;

  GetDeliveriesUsecase(this.repository);

  Future<Result<List<Delivery>>> call({DeliveryStatus? status}) async {
    return await repository.getDeliveries(status: status);
  }
}
