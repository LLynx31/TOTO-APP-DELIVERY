import '../../entities/delivery.dart';
import '../../repositories/delivery_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour récupérer une livraison par ID
class GetDeliveryUsecase {
  final DeliveryRepository repository;

  GetDeliveryUsecase(this.repository);

  Future<Result<Delivery>> call(String id) async {
    if (id.isEmpty) {
      return const Failure('ID de livraison invalide');
    }

    return await repository.getDeliveryById(id);
  }
}
