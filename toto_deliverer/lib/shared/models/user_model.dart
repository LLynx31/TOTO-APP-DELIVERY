class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? photoUrl;
  final List<AddressModel> favoriteAddresses;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.photoUrl,
    this.favoriteAddresses = const [],
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      favoriteAddresses: (json['favoriteAddresses'] as List<dynamic>?)
              ?.map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
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
      'favoriteAddresses':
          favoriteAddresses.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? photoUrl,
    List<AddressModel>? favoriteAddresses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteAddresses: favoriteAddresses ?? this.favoriteAddresses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AddressModel {
  final String? id;
  final String address;
  final double latitude;
  final double longitude;
  final String? label; // ex: "Maison", "Bureau"
  final String? phone; // Numéro de téléphone du contact à cette adresse
  final String? contactName; // Nom du contact (ex: receiver_name pour livraison)
  final bool isDefault;

  AddressModel({
    this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.label,
    this.phone,
    this.contactName,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      label: json['label'] as String?,
      phone: json['phone'] as String?,
      contactName: json['contactName'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'phone': phone,
      'contactName': contactName,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? address,
    double? latitude,
    double? longitude,
    String? label,
    String? phone,
    String? contactName,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      phone: phone ?? this.phone,
      contactName: contactName ?? this.contactName,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
