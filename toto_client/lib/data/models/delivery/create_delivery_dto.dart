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

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_phone': deliveryPhone,
      'receiver_name': receiverName,
    };

    if (pickupPhone != null) json['pickup_phone'] = pickupPhone;
    if (packageDescription != null) json['package_description'] = packageDescription;
    if (packageWeight != null) json['package_weight'] = packageWeight;
    if (specialInstructions != null) json['special_instructions'] = specialInstructions;

    return json;
  }
}
