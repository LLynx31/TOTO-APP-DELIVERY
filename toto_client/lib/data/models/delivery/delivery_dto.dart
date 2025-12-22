/// DTO pour une livraison (correspond au modèle backend)
class DeliveryDto {
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
  final String? packageDescription;
  final double? packageWeight;
  final String qrCodePickup;
  final String qrCodeDelivery;
  final String status;
  final double price;
  final double? distanceKm;
  final String? specialInstructions;
  final String? deliveryCode; // Code 4 chiffres pour validation sans app
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? updatedAt;

  const DeliveryDto({
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
    this.packageDescription,
    this.packageWeight,
    required this.qrCodePickup,
    required this.qrCodeDelivery,
    required this.status,
    required this.price,
    this.distanceKm,
    this.specialInstructions,
    this.deliveryCode,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.updatedAt,
  });

  factory DeliveryDto.fromJson(Map<String, dynamic> json) {
    return DeliveryDto(
      id: json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      delivererId: json['deliverer_id'],
      pickupAddress: json['pickup_address'] ?? '',
      pickupLatitude: (json['pickup_latitude'] ?? 0).toDouble(),
      pickupLongitude: (json['pickup_longitude'] ?? 0).toDouble(),
      pickupPhone: json['pickup_phone'],
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryLatitude: (json['delivery_latitude'] ?? 0).toDouble(),
      deliveryLongitude: (json['delivery_longitude'] ?? 0).toDouble(),
      deliveryPhone: json['delivery_phone'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      packageDescription: json['package_description'],
      packageWeight: json['package_weight']?.toDouble(),
      qrCodePickup: json['qr_code_pickup'] ?? '',
      qrCodeDelivery: json['qr_code_delivery'] ?? '',
      status: json['status'] ?? 'pending',
      price: (json['price'] ?? 0).toDouble(),
      distanceKm: json['distance_km']?.toDouble(),
      specialInstructions: json['special_instructions'],
      deliveryCode: json['delivery_code'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
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
        'status': status,
        'price': price,
        'distance_km': distanceKm,
        'special_instructions': specialInstructions,
        'delivery_code': deliveryCode,
        'created_at': createdAt.toIso8601String(),
        'accepted_at': acceptedAt?.toIso8601String(),
        'picked_up_at': pickedUpAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
        'cancelled_at': cancelledAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
