import '../entities/rating.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Paramètres pour créer une notation
class CreateRatingParams {
  final String deliveryId;
  final int stars;
  final String? comment;

  const CreateRatingParams({
    required this.deliveryId,
    required this.stars,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'delivery_id': deliveryId,
      'stars': stars,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}

/// Repository interface pour les notations
abstract class RatingRepository {
  /// Crée une nouvelle notation pour une livraison
  Future<Result<Rating>> createRating(CreateRatingParams params);

  /// Récupère la notation d'un utilisateur pour une livraison
  Future<Result<Rating?>> getRatingForDelivery(String deliveryId);

  /// Vérifie si l'utilisateur a déjà noté cette livraison
  Future<Result<bool>> hasRated(String deliveryId);
}
