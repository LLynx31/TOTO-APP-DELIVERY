enum NotificationType {
  deliveryAccepted,
  delivererOnWayToPickup,
  packagePickedUp,
  delivererOnWayToDestination,
  packageDelivered,
  deliveryCancelled,
  other;

  String get displayName {
    switch (this) {
      case NotificationType.deliveryAccepted:
        return 'Livraison acceptée';
      case NotificationType.delivererOnWayToPickup:
        return 'Livreur en route vers A';
      case NotificationType.packagePickedUp:
        return 'Colis récupéré';
      case NotificationType.delivererOnWayToDestination:
        return 'Livreur en route vers B';
      case NotificationType.packageDelivered:
        return 'Colis livré avec succès';
      case NotificationType.deliveryCancelled:
        return 'Livraison annulée';
      case NotificationType.other:
        return 'Notification';
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? deliveryId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.deliveryId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.other,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      deliveryId: json['deliveryId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'deliveryId': deliveryId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? deliveryId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      deliveryId: deliveryId ?? this.deliveryId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
