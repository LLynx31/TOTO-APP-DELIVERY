import 'package:equatable/equatable.dart';

/// Statut de livraison
enum DeliveryStatus {
  pending,
  accepted,
  pickupInProgress,
  pickedUp,
  deliveryInProgress,
  delivered,
  cancelled;

  static DeliveryStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'accepted':
        return DeliveryStatus.accepted;
      case 'pickupinprogress':
        return DeliveryStatus.pickupInProgress;
      case 'pickedup':
        return DeliveryStatus.pickedUp;
      case 'deliveryinprogress':
        return DeliveryStatus.deliveryInProgress;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pending;
    }
  }
}

/// Entité Delivery (domain layer)
class Delivery extends Equatable {
  final String id;
  final String clientId;
  final String? delivererId;
  final Location pickupLocation;
  final Location deliveryLocation;
  final Package package;
  final QRCodes qrCodes;
  final DeliveryStatus status;
  final double price;
  final double? distanceKm;
  final String? specialInstructions;
  final DeliveryTimestamps timestamps;
  final String? deliveryCode; // Code 4 chiffres pour validation sans app

  const Delivery({
    required this.id,
    required this.clientId,
    this.delivererId,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.package,
    required this.qrCodes,
    required this.status,
    required this.price,
    this.distanceKm,
    this.specialInstructions,
    required this.timestamps,
    this.deliveryCode,
  });

  @override
  List<Object?> get props => [
        id,
        clientId,
        delivererId,
        pickupLocation,
        deliveryLocation,
        package,
        qrCodes,
        status,
        price,
        distanceKm,
        specialInstructions,
        timestamps,
        deliveryCode,
      ];

  bool get isActive => status != DeliveryStatus.delivered && status != DeliveryStatus.cancelled;
  bool get isCompleted => status == DeliveryStatus.delivered;
  bool get isCancelled => status == DeliveryStatus.cancelled;
}

/// Location
class Location extends Equatable {
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;

  const Location({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
  });

  @override
  List<Object?> get props => [address, latitude, longitude, phone];
}

/// Package
class Package extends Equatable {
  final String receiverName;
  final String receiverPhone;
  final String? description;
  final double? weight;

  const Package({
    required this.receiverName,
    required this.receiverPhone,
    this.description,
    this.weight,
  });

  @override
  List<Object?> get props => [receiverName, receiverPhone, description, weight];
}

/// QR Codes
class QRCodes extends Equatable {
  final String pickup;
  final String delivery;

  const QRCodes({
    required this.pickup,
    required this.delivery,
  });

  @override
  List<Object?> get props => [pickup, delivery];
}

/// Timestamps
class DeliveryTimestamps extends Equatable {
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  const DeliveryTimestamps({
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  @override
  List<Object?> get props => [createdAt, acceptedAt, pickedUpAt, deliveredAt, cancelledAt];
}
