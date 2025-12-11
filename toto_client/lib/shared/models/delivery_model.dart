import 'user_model.dart';

enum DeliveryStatus {
  pending,
  accepted,
  pickupInProgress,
  pickedUp,
  deliveryInProgress,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.accepted:
        return 'Acceptée';
      case DeliveryStatus.pickupInProgress:
        return 'En route vers A';
      case DeliveryStatus.pickedUp:
        return 'Colis récupéré';
      case DeliveryStatus.deliveryInProgress:
        return 'En route vers B';
      case DeliveryStatus.delivered:
        return 'Livré';
      case DeliveryStatus.cancelled:
        return 'Annulé';
    }
  }
}

enum DeliveryMode {
  standard,
  express;

  String get displayName {
    switch (this) {
      case DeliveryMode.standard:
        return 'Standard';
      case DeliveryMode.express:
        return 'Express';
    }
  }

  String get duration {
    switch (this) {
      case DeliveryMode.standard:
        return '2 heures';
      case DeliveryMode.express:
        return '45 minutes';
    }
  }
}

enum PackageSize {
  small,
  medium,
  large;

  String get displayName {
    switch (this) {
      case PackageSize.small:
        return 'Petit';
      case PackageSize.medium:
        return 'Moyen';
      case PackageSize.large:
        return 'Grand';
    }
  }
}

class DeliveryModel {
  final String id;
  final String customerId;
  final String? delivererId;
  final PackageModel package;
  final AddressModel pickupAddress;
  final AddressModel deliveryAddress;
  final DeliveryMode mode;
  final DeliveryStatus status;
  final double price;
  final bool hasInsurance;
  final double? insuranceAmount;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? qrCode;
  final int? rating;
  final String? comment;

  DeliveryModel({
    required this.id,
    required this.customerId,
    this.delivererId,
    required this.package,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.mode,
    required this.status,
    required this.price,
    this.hasInsurance = false,
    this.insuranceAmount,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.qrCode,
    this.rating,
    this.comment,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      delivererId: json['delivererId'] as String?,
      package: PackageModel.fromJson(json['package'] as Map<String, dynamic>),
      pickupAddress: AddressModel.fromJson(
        json['pickupAddress'] as Map<String, dynamic>,
      ),
      deliveryAddress: AddressModel.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>,
      ),
      mode: DeliveryMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => DeliveryMode.standard,
      ),
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      price: (json['price'] as num).toDouble(),
      hasInsurance: json['hasInsurance'] as bool? ?? false,
      insuranceAmount: json['insuranceAmount'] != null
          ? (json['insuranceAmount'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      qrCode: json['qrCode'] as String?,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'delivererId': delivererId,
      'package': package.toJson(),
      'pickupAddress': pickupAddress.toJson(),
      'deliveryAddress': deliveryAddress.toJson(),
      'mode': mode.name,
      'status': status.name,
      'price': price,
      'hasInsurance': hasInsurance,
      'insuranceAmount': insuranceAmount,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'qrCode': qrCode,
      'rating': rating,
      'comment': comment,
    };
  }

  DeliveryModel copyWith({
    String? id,
    String? customerId,
    String? delivererId,
    PackageModel? package,
    AddressModel? pickupAddress,
    AddressModel? deliveryAddress,
    DeliveryMode? mode,
    DeliveryStatus? status,
    double? price,
    bool? hasInsurance,
    double? insuranceAmount,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? qrCode,
    int? rating,
    String? comment,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      delivererId: delivererId ?? this.delivererId,
      package: package ?? this.package,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      price: price ?? this.price,
      hasInsurance: hasInsurance ?? this.hasInsurance,
      insuranceAmount: insuranceAmount ?? this.insuranceAmount,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      qrCode: qrCode ?? this.qrCode,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }
}

class PackageModel {
  final PackageSize size;
  final double weight;
  final String? description;
  final String? photoUrl;

  PackageModel({
    required this.size,
    required this.weight,
    this.description,
    this.photoUrl,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      size: PackageSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => PackageSize.medium,
      ),
      weight: (json['weight'] as num).toDouble(),
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size.name,
      'weight': weight,
      'description': description,
      'photoUrl': photoUrl,
    };
  }

  PackageModel copyWith({
    PackageSize? size,
    double? weight,
    String? description,
    String? photoUrl,
  }) {
    return PackageModel(
      size: size ?? this.size,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
