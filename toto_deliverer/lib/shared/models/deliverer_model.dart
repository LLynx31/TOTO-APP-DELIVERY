/// Modèle pour les informations du livreur
class DelivererModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? photoUrl;
  final bool isOnline;
  final bool isVerified;
  final double rating;
  final int totalDeliveries;
  final VehicleInfo vehicle;
  final List<DocumentInfo> documents;
  final DateTime createdAt;

  DelivererModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.photoUrl,
    this.isOnline = false,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    required this.vehicle,
    this.documents = const [],
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  DelivererModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? photoUrl,
    bool? isOnline,
    bool? isVerified,
    double? rating,
    int? totalDeliveries,
    VehicleInfo? vehicle,
    List<DocumentInfo>? documents,
    DateTime? createdAt,
  }) {
    return DelivererModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      vehicle: vehicle ?? this.vehicle,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'vehicle': vehicle.toJson(),
      'documents': documents.map((doc) => doc.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DelivererModel.fromJson(Map<String, dynamic> json) {
    return DelivererModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      vehicle: VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>),
      documents: (json['documents'] as List<dynamic>?)
              ?.map((doc) => DocumentInfo.fromJson(doc as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Informations sur le véhicule du livreur
class VehicleInfo {
  final String type; // "Moto", "Voiture", "Vélo"
  final String plate;
  final String? photoUrl;

  VehicleInfo({
    required this.type,
    required this.plate,
    this.photoUrl,
  });

  VehicleInfo copyWith({
    String? type,
    String? plate,
    String? photoUrl,
  }) {
    return VehicleInfo(
      type: type ?? this.type,
      plate: plate ?? this.plate,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'plate': plate,
      'photoUrl': photoUrl,
    };
  }

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      type: json['type'] as String,
      plate: json['plate'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

/// Informations sur les documents de vérification
class DocumentInfo {
  final String type; // "drivingLicense", "idCard", "vehicleRegistration"
  final String? url;
  final bool isVerified;
  final DateTime? uploadedAt;

  DocumentInfo({
    required this.type,
    this.url,
    this.isVerified = false,
    this.uploadedAt,
  });

  DocumentInfo copyWith({
    String? type,
    String? url,
    bool? isVerified,
    DateTime? uploadedAt,
  }) {
    return DocumentInfo(
      type: type ?? this.type,
      url: url ?? this.url,
      isVerified: isVerified ?? this.isVerified,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'isVerified': isVerified,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      type: json['type'] as String,
      url: json['url'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
    );
  }
}
