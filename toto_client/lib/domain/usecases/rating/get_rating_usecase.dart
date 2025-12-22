import '../../entities/rating.dart';
import '../../repositories/rating_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour récupérer une notation
class GetRatingUsecase {
  final RatingRepository repository;

  GetRatingUsecase(this.repository);

  Future<Result<Rating?>> call(String deliveryId) async {
    return await repository.getRatingForDelivery(deliveryId);
  }
}
