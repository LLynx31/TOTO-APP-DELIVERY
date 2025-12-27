/// Statut de vérification KYC
enum KycStatus {
  pending,   // En attente de validation admin
  approved,  // Validé par l'admin
  rejected;  // Rejeté par l'admin

  String get displayName {
    switch (this) {
      case KycStatus.pending:
        return 'En attente de validation';
      case KycStatus.approved:
        return 'Compte vérifié';
      case KycStatus.rejected:
        return 'Documents rejetés';
    }
  }

  String get description {
    switch (this) {
      case KycStatus.pending:
        return 'Votre compte est en cours de vérification par notre équipe. Vous serez notifié dès que votre compte sera validé.';
      case KycStatus.approved:
        return 'Votre compte a été vérifié. Vous pouvez maintenant accepter des courses.';
      case KycStatus.rejected:
        return 'Vos documents ont été rejetés. Veuillez les soumettre à nouveau.';
    }
  }

  /// Parse depuis le backend
  static KycStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      default:
        return KycStatus.pending;
    }
  }
}

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
  final KycStatus kycStatus; // Statut de validation admin
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
    this.kycStatus = KycStatus.pending,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    required this.vehicle,
    this.documents = const [],
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  /// Vérifie si le livreur peut accepter des courses
  bool get canAcceptDeliveries => isVerified && kycStatus == KycStatus.approved;

  /// Vérifie si le compte est en attente de validation
  bool get isPendingValidation => kycStatus == KycStatus.pending;

  DelivererModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? photoUrl,
    bool? isOnline,
    bool? isVerified,
    KycStatus? kycStatus,
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
      kycStatus: kycStatus ?? this.kycStatus,
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
      'kycStatus': kycStatus.name,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'vehicle': vehicle.toJson(),
      'documents': documents.map((doc) => doc.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DelivererModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (frontend) and snake_case (backend) formats
    final fullName = (json['full_name'] ?? json['fullName'] ?? '').toString().trim();
    final nameParts = fullName.isNotEmpty ? fullName.split(' ') : <String>[];

    // Extraire firstName et lastName du full_name ou utiliser les valeurs directes
    String firstName = json['firstName']?.toString() ?? '';
    String lastName = json['lastName']?.toString() ?? '';

    // Si firstName est vide mais qu'on a des nameParts, utiliser le premier
    if (firstName.isEmpty && nameParts.isNotEmpty) {
      firstName = nameParts.first;
    }
    // Si lastName est vide et qu'on a plus d'une partie, utiliser le reste
    if (lastName.isEmpty && nameParts.length > 1) {
      lastName = nameParts.sublist(1).join(' ');
    }

    // Fallback values si tout est vide
    if (firstName.isEmpty) firstName = 'Livreur';

    // Parser le phone avec logs pour debug
    // L'ApiClient transforme phone_number en phoneNumber (camelCase)
    final phone = json['phoneNumber']?.toString() ??
                  json['phone_number']?.toString() ??
                  json['phone']?.toString() ?? '';
    print('📱 DelivererModel.fromJson - phone: "$phone"');
    if (phone.isEmpty) {
      print('⚠️ ATTENTION: phone est vide!');
      print('   JSON keys: ${json.keys.toList()}');
    }

    return DelivererModel(
      id: json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: json['email'] as String?,
      photoUrl: (json['photo_url'] ?? json['photoUrl']) as String?,
      isOnline: json['is_available'] == true || json['isOnline'] == true,
      isVerified: json['is_verified'] == true || json['isVerified'] == true,
      kycStatus: KycStatus.fromString(json['kyc_status']?.toString() ?? json['kycStatus']?.toString()),
      rating: _parseRating(json['rating']),
      totalDeliveries: json['total_deliveries'] ?? json['totalDeliveries'] ?? 0,
      vehicle: VehicleInfo.fromBackendJson(json),
      documents: _parseDocuments(json),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Parse le rating qui peut être un String, int ou double
  static double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  /// Parse la date de création
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  /// Parse les documents KYC depuis le backend
  static List<DocumentInfo> _parseDocuments(Map<String, dynamic> json) {
    final List<DocumentInfo> docs = [];

    // Parse les URLs de documents KYC du backend (support camelCase et snake_case)
    final driverLicenseUrl = json['driverLicenseUrl'] ?? json['driver_license_url'];
    final idCardFrontUrl = json['idCardFrontUrl'] ?? json['id_card_front_url'];
    final kycStatus = json['kycStatus'] ?? json['kyc_status'];
    final kycSubmittedAt = json['kycSubmittedAt'] ?? json['kyc_submitted_at'];

    if (driverLicenseUrl != null) {
      docs.add(DocumentInfo(
        type: 'drivingLicense',
        url: driverLicenseUrl,
        isVerified: kycStatus == 'approved',
        uploadedAt: _parseDate(kycSubmittedAt),
      ));
    }
    if (idCardFrontUrl != null) {
      docs.add(DocumentInfo(
        type: 'idCard',
        url: idCardFrontUrl,
        isVerified: kycStatus == 'approved',
        uploadedAt: _parseDate(kycSubmittedAt),
      ));
    }

    // Support legacy format
    if (json['documents'] != null && json['documents'] is List) {
      for (final doc in json['documents']) {
        docs.add(DocumentInfo.fromJson(doc as Map<String, dynamic>));
      }
    }

    return docs;
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

  /// Parse depuis les données du backend (snake_case, champs au niveau racine)
  factory VehicleInfo.fromBackendJson(Map<String, dynamic> json) {
    // Backend stocke vehicle_type et license_plate au niveau racine du deliverer
    // ApiClient transforme snake_case → camelCase, donc vérifier les deux
    final vehicleType = json['vehicleType']?.toString() ??
                       json['vehicle_type']?.toString() ??
                       json['type']?.toString() ??
                       'Non spécifié';

    final licensePlate = json['licensePlate']?.toString() ??
                        json['license_plate']?.toString() ??
                        json['plate']?.toString() ??
                        'Non spécifié';

    final photoUrl = json['vehiclePhotoUrl']?.toString() ??
                    json['vehicle_photo_url']?.toString() ??
                    json['photoUrl']?.toString();

    print('🚗 VehicleInfo.fromBackendJson:');
    print('   vehicleType: "$vehicleType"');
    print('   licensePlate: "$licensePlate"');
    print('   photoUrl: "$photoUrl"');

    return VehicleInfo(
      type: vehicleType,
      plate: licensePlate,
      photoUrl: photoUrl,
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
