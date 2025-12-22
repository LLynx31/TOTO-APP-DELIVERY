import '../../../domain/entities/rating.dart';

/// DTO pour Rating - Mapping backend → frontend
class RatingDto {
  final String id;
  final String deliveryId;
  final String ratedById;
  final String ratedUserId;
  final int stars;
  final String? comment;
  final String createdAt;

  const RatingDto({
    required this.id,
    required this.deliveryId,
    required this.ratedById,
    required this.ratedUserId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  /// Factory constructor pour créer depuis JSON (backend snake_case)
  factory RatingDto.fromJson(Map<String, dynamic> json) {
    return RatingDto(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      ratedById: json['rated_by_id'] as String,
      ratedUserId: json['rated_user_id'] as String,
      stars: json['stars'] as int,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  /// Convertir vers JSON (pour envoyer au backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'rated_by_id': ratedById,
      'rated_user_id': ratedUserId,
      'stars': stars,
      'comment': comment,
      'created_at': createdAt,
    };
  }

  /// Convertir vers Rating entity (domain layer)
  Rating toEntity() {
    return Rating(
      id: id,
      deliveryId: deliveryId,
      ratedById: ratedById,
      ratedUserId: ratedUserId,
      stars: stars,
      comment: comment,
      createdAt: DateTime.parse(createdAt),
    );
  }

  /// Factory constructor depuis Rating entity
  factory RatingDto.fromEntity(Rating rating) {
    return RatingDto(
      id: rating.id,
      deliveryId: rating.deliveryId,
      ratedById: rating.ratedById,
      ratedUserId: rating.ratedUserId,
      stars: rating.stars,
      comment: rating.comment,
      createdAt: rating.createdAt.toIso8601String(),
    );
  }
}
