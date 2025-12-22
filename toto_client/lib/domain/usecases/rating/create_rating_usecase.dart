import '../../entities/rating.dart';
import '../../repositories/rating_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour créer une notation
class CreateRatingUsecase {
  final RatingRepository repository;

  CreateRatingUsecase(this.repository);

  Future<Result<Rating>> call(CreateRatingParams params) async {
    // Validation
    if (params.stars < 1 || params.stars > 5) {
      return const Failure('Le nombre d\'étoiles doit être entre 1 et 5');
    }

    if (params.comment != null && params.comment!.length > 500) {
      return const Failure('Le commentaire ne peut pas dépasser 500 caractères');
    }

    return await repository.createRating(params);
  }
}
