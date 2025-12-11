enum DeliveryStatus {
  pending,
  accepted,
  pickupInProgress,
  pickedUp,
  deliveryInProgress,
  delivered,
  cancelled,
}

class DeliveryModel {
  final String id;
  final String clientId;
  final String? delivererId;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? pickupPhone;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String deliveryPhone;
  final String receiverName;
  final String packageDescription;
  final double? packageWeight;
  final String qrCodePickup;
  final String qrCodeDelivery;
  final DeliveryStatus status;
  final double price;
  final double distanceKm;
  final String? specialInstructions;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryModel({
    required this.id,
    required this.clientId,
    this.delivererId,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.pickupPhone,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryPhone,
    required this.receiverName,
    required this.packageDescription,
    this.packageWeight,
    required this.qrCodePickup,
    required this.qrCodeDelivery,
    required this.status,
    required this.price,
    required this.distanceKm,
    this.specialInstructions,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'],
      clientId: json['client_id'],
      delivererId: json['deliverer_id'],
      pickupAddress: json['pickup_address'],
      pickupLatitude: double.parse(json['pickup_latitude'].toString()),
      pickupLongitude: double.parse(json['pickup_longitude'].toString()),
      pickupPhone: json['pickup_phone'],
      deliveryAddress: json['delivery_address'],
      deliveryLatitude: double.parse(json['delivery_latitude'].toString()),
      deliveryLongitude: double.parse(json['delivery_longitude'].toString()),
      deliveryPhone: json['delivery_phone'],
      receiverName: json['receiver_name'],
      packageDescription: json['package_description'],
      packageWeight: json['package_weight'] != null
          ? double.parse(json['package_weight'].toString())
          : null,
      qrCodePickup: json['qr_code_pickup'],
      qrCodeDelivery: json['qr_code_delivery'],
      status: _statusFromString(json['status']),
      price: double.parse(json['price'].toString()),
      distanceKm: double.parse(json['distance_km'].toString()),
      specialInstructions: json['special_instructions'],
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'deliverer_id': delivererId,
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'pickup_phone': pickupPhone,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_phone': deliveryPhone,
      'receiver_name': receiverName,
      'package_description': packageDescription,
      'package_weight': packageWeight,
      'qr_code_pickup': qrCodePickup,
      'qr_code_delivery': qrCodeDelivery,
      'status': _statusToString(status),
      'price': price,
      'distance_km': distanceKm,
      'special_instructions': specialInstructions,
      'accepted_at': acceptedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static DeliveryStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'accepted':
        return DeliveryStatus.accepted;
      case 'pickup_in_progress':
        return DeliveryStatus.pickupInProgress;
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'delivery_in_progress':
        return DeliveryStatus.deliveryInProgress;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pending;
    }
  }

  static String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.accepted:
        return 'accepted';
      case DeliveryStatus.pickupInProgress:
        return 'pickup_in_progress';
      case DeliveryStatus.pickedUp:
        return 'picked_up';
      case DeliveryStatus.deliveryInProgress:
        return 'delivery_in_progress';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.accepted:
        return 'Acceptée';
      case DeliveryStatus.pickupInProgress:
        return 'Ramassage en cours';
      case DeliveryStatus.pickedUp:
        return 'Colis récupéré';
      case DeliveryStatus.deliveryInProgress:
        return 'Livraison en cours';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }
}
