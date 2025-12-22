import '../../core/network/api_exception.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/remote/rating_remote_datasource.dart';
import '../models/rating/rating_model.dart';
import 'auth_repository_impl.dart';

/// Implémentation du RatingRepository
class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDatasource remoteDatasource;

  RatingRepositoryImpl(this.remoteDatasource);

  @override
  Future<Result<Rating>> createRating(CreateRatingParams params) async {
    try {
      final response = await remoteDatasource.createRating(
        params.deliveryId,
        params.toJson(),
      );

      // Le backend retourne le rating créé
      final ratingDto = RatingDto.fromJson(response as Map<String, dynamic>);
      return Success(ratingDto.toEntity());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Une erreur est survenue lors de la notation: ${e.toString()}');
    }
  }

  @override
  Future<Result<Rating?>> getRatingForDelivery(String deliveryId) async {
    try {
      final response = await remoteDatasource.getRatingForDelivery(deliveryId);

      // Si le backend retourne null ou un objet vide, pas de rating
      if (response == null || response is! Map<String, dynamic>) {
        return const Success(null);
      }

      final ratingDto = RatingDto.fromJson(response);
      return Success(ratingDto.toEntity());
    } on ApiException catch (e) {
      // Si c'est une erreur 404, pas de rating trouvé
      if (e.message.contains('404') || e.message.contains('not found')) {
        return const Success(null);
      }
      return Failure(e.message);
    } catch (e) {
      return Failure('Une erreur est survenue lors de la récupération de la notation: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> hasRated(String deliveryId) async {
    try {
      final hasRated = await remoteDatasource.hasRated(deliveryId);
      return Success(hasRated);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      // En cas d'erreur, considérer que l'utilisateur n'a pas noté
      return const Success(false);
    }
  }
}
