import '../../entities/delivery.dart';
import '../../repositories/delivery_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour annuler une livraison
class CancelDeliveryUsecase {
  final DeliveryRepository repository;

  CancelDeliveryUsecase(this.repository);

  Future<Result<Delivery>> call(String id) async {
    if (id.isEmpty) {
      return const Failure('ID de livraison invalide');
    }

    return await repository.cancelDelivery(id);
  }
}
