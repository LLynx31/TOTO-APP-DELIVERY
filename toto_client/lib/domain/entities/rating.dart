import 'package:equatable/equatable.dart';

/// Entité Rating (domain layer)
class Rating extends Equatable {
  final String id;
  final String deliveryId;
  final String ratedById;      // ID de l'utilisateur qui note
  final String ratedUserId;    // ID de l'utilisateur qui est noté
  final int stars;             // 1-5 étoiles
  final String? comment;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.deliveryId,
    required this.ratedById,
    required this.ratedUserId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        deliveryId,
        ratedById,
        ratedUserId,
        stars,
        comment,
        createdAt,
      ];

  Rating copyWith({
    String? id,
    String? deliveryId,
    String? ratedById,
    String? ratedUserId,
    int? stars,
    String? comment,
    DateTime? createdAt,
  }) {
    return Rating(
      id: id ?? this.id,
      deliveryId: deliveryId ?? this.deliveryId,
      ratedById: ratedById ?? this.ratedById,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
