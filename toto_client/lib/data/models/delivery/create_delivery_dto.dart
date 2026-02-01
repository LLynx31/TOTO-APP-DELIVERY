/// DTO pour créer une livraison
class CreateDeliveryDto {
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
  final String? specialInstructions;

  const CreateDeliveryDto({
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
    this.specialInstructions,
  });

  /// Formate le numéro de téléphone au format international +XXXXXXXXXXX
  /// Par défaut, utilise +225 (Côte d'Ivoire) si pas d'indicatif présent
  static String _formatPhone(String phone) {
    // Nettoyer le numéro (enlever espaces, tirets, etc.)
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    // Si déjà au format international (commence par +)
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Si commence par 00 (format international)
    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }

    // Si commence par 0, c'est un numéro local - ajouter +225 par défaut (Côte d'Ivoire)
    if (cleaned.startsWith('0')) {
      return '+225${cleaned.substring(1)}';
    }

    // Sinon, ajouter simplement +225 (indicatif par défaut)
    return '+225$cleaned';
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_phone': _formatPhone(deliveryPhone),
      'receiver_name': receiverName,
    };

    if (pickupPhone != null && pickupPhone!.isNotEmpty) {
      json['pickup_phone'] = _formatPhone(pickupPhone!);
    }
    if (packageDescription != null) json['package_description'] = packageDescription;
    if (packageWeight != null) json['package_weight'] = packageWeight;
    if (specialInstructions != null) json['special_instructions'] = specialInstructions;

    return json;
  }
}
