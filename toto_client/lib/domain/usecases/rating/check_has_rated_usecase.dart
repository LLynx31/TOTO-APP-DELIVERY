import '../../repositories/rating_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour vérifier si l'utilisateur a déjà noté
class CheckHasRatedUsecase {
  final RatingRepository repository;

  CheckHasRatedUsecase(this.repository);

  Future<Result<bool>> call(String deliveryId) async {
    return await repository.hasRated(deliveryId);
  }
}
