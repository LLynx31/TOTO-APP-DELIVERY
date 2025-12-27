import 'package:toto_deliverer/core/adapters/base_adapter.dart';
import 'package:toto_deliverer/shared/models/delivery_model.dart';
import 'package:toto_deliverer/shared/models/user_model.dart';

/// Adapter pour transformer les livraisons backend → frontend
///
/// Mapping Backend (snake_case) → Frontend (camelCase):
/// - pickup_address, pickup_latitude, pickup_longitude → pickupAddress (AddressModel)
/// - delivery_address, delivery_latitude, delivery_longitude → deliveryAddress (AddressModel)
/// - package_description, package_weight → package (PackageModel avec size inférée)
/// - qr_code_delivery → qrCode (le QR de livraison, pas celui de pickup)
/// - delivery_code → code 4 chiffres (fallback si pas d'app)
class DeliveryAdapter {
  /// Convertit une livraison backend en modèle frontend
  ///
  /// Exemple backend:
  /// ```json
  /// {
  ///   "id": "123",
  ///   "client_id": "456",
  ///   "deliverer_id": "789",
  ///   "pickup_address": "Cocody Angré",
  ///   "pickup_latitude": 5.3599517,
  ///   "pickup_longitude": -3.9810350,
  ///   "delivery_address": "Plateau",
  ///   "delivery_latitude": 5.3250984,
  ///   "delivery_longitude": -4.0267813,
  ///   "package_description": "Documents",
  ///   "package_weight": 1.5,
  ///   "price": 2500,
  ///   "distance_km": 8.5,
  ///   "status": "pending",
  ///   "created_at": "2024-01-01T10:00:00Z",
  ///   "qr_code_delivery": "TOTO-DELIVERY-...",
  ///   "delivery_code": "1234"
  /// }
  /// ```
  static DeliveryModel fromBackend(Map<String, dynamic> json) {
    // Note: Les données arrivent en camelCase car ApiClient les transforme automatiquement
    // Extraire les données avec null-safety (supporte snake_case ET camelCase)
    final id = json['id'] as String;
    final clientId = (json['clientId'] ?? json['client_id']) as String;
    final delivererId = (json['delivererId'] ?? json['deliverer_id']) as String?;

    // Construire pickupAddress depuis les champs séparés
    final pickupAddress = _buildAddressFromFields(
      address: (json['pickupAddress'] ?? json['pickup_address']) as String,
      latitude: BaseAdapter.toDouble(json['pickupLatitude'] ?? json['pickup_latitude'])!,
      longitude: BaseAdapter.toDouble(json['pickupLongitude'] ?? json['pickup_longitude'])!,
      phone: (json['pickupPhone'] ?? json['pickup_phone']) as String?, // Optionnel
    );

    // Construire deliveryAddress depuis les champs séparés
    final deliveryAddress = _buildAddressFromFields(
      address: (json['deliveryAddress'] ?? json['delivery_address']) as String,
      latitude: BaseAdapter.toDouble(json['deliveryLatitude'] ?? json['delivery_latitude'])!,
      longitude: BaseAdapter.toDouble(json['deliveryLongitude'] ?? json['delivery_longitude'])!,
      phone: (json['deliveryPhone'] ?? json['delivery_phone']) as String?, // Optionnel
      receiverName: (json['receiverName'] ?? json['receiver_name']) as String?, // Optionnel
    );

    // Construire package avec inférence de la taille
    final package = _buildPackageFromFields(
      description: (json['packageDescription'] ?? json['package_description']) as String?,
      weight: BaseAdapter.toDouble(json['packageWeight'] ?? json['package_weight']) ?? 2.0,
      photoUrl: (json['packagePhotoUrl'] ?? json['package_photo_url']) as String?, // Si backend le supporte
    );

    // Déterminer le mode (Standard vs Express)
    final mode = _inferMode(
      distanceKm: BaseAdapter.toDouble(json['distanceKm'] ?? json['distance_km']),
      // Le backend pourrait avoir un champ 'mode' dans le futur
      explicitMode: json['mode'] as String?,
    );

    // Mapper le status
    final status = _mapStatus(json['status'] as String);

    // Extraire le prix
    final price = BaseAdapter.toDouble(json['price'])!;

    // Assurance (si backend le supporte)
    final hasInsurance = BaseAdapter.toBool(json['hasInsurance'] ?? json['has_insurance']) ?? false;
    final insuranceAmount = BaseAdapter.toDouble(json['insuranceAmount'] ?? json['insurance_amount']);

    // Dates
    final createdAt = BaseAdapter.parseDate(json['createdAt'] ?? json['created_at'])!;
    final acceptedAt = BaseAdapter.parseDate(json['acceptedAt'] ?? json['accepted_at']);
    final pickedUpAt = BaseAdapter.parseDate(json['pickedUpAt'] ?? json['picked_up_at']);
    final deliveredAt = BaseAdapter.parseDate(json['deliveredAt'] ?? json['delivered_at']);

    // QR code de livraison (pas celui de pickup)
    final qrCode = (json['qrCodeDelivery'] ?? json['qr_code_delivery']) as String?;

    // Rating si livraison terminée
    final rating = BaseAdapter.toInt(json['rating']);
    final comment = json['comment'] as String?;

    return DeliveryModel(
      id: id,
      customerId: clientId,
      delivererId: delivererId,
      package: package,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      mode: mode,
      status: status,
      price: price,
      hasInsurance: hasInsurance,
      insuranceAmount: insuranceAmount,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      qrCode: qrCode,
      rating: rating,
      comment: comment,
    );
  }

  /// Convertit un modèle frontend en données pour backend
  ///
  /// Note: Rarement utilisé car le livreur ne crée pas de livraisons,
  /// mais utile pour les mises à jour (ex: changer le status)
  static Map<String, dynamic> toBackend(DeliveryModel model) {
    return {
      'id': model.id,
      'client_id': model.customerId,
      'deliverer_id': model.delivererId,
      'pickup_address': model.pickupAddress.address,
      'pickup_latitude': model.pickupAddress.latitude,
      'pickup_longitude': model.pickupAddress.longitude,
      'delivery_address': model.deliveryAddress.address,
      'delivery_latitude': model.deliveryAddress.latitude,
      'delivery_longitude': model.deliveryAddress.longitude,
      'package_description': model.package.description,
      'package_weight': model.package.weight,
      'price': model.price,
      'status': _statusToBackend(model.status),
      'created_at': model.createdAt.toIso8601String(),
      'accepted_at': model.acceptedAt?.toIso8601String(),
      'picked_up_at': model.pickedUpAt?.toIso8601String(),
      'delivered_at': model.deliveredAt?.toIso8601String(),
    };
  }

  /// Construit un AddressModel depuis les champs backend séparés
  static AddressModel _buildAddressFromFields({
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? receiverName,
  }) {
    return AddressModel(
      address: address,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
      contactName: receiverName,
      isDefault: false,
    );
  }

  /// Construit un PackageModel avec inférence de la taille depuis le poids
  ///
  /// Règles d'inférence:
  /// - < 2 kg → Small
  /// - 2-5 kg → Medium
  /// - > 5 kg → Large
  static PackageModel _buildPackageFromFields({
    String? description,
    required double weight,
    String? photoUrl,
  }) {
    final size = _inferPackageSize(weight);

    return PackageModel(
      size: size,
      weight: weight,
      description: description,
      photoUrl: photoUrl,
    );
  }

  /// Infère la taille du colis depuis son poids
  static PackageSize _inferPackageSize(double weight) {
    if (weight < 2.0) {
      return PackageSize.small;
    } else if (weight <= 5.0) {
      return PackageSize.medium;
    } else {
      return PackageSize.large;
    }
  }

  /// Infère le mode de livraison
  ///
  /// Si le backend fournit un champ 'mode', l'utiliser.
  /// Sinon, inférer depuis la distance:
  /// - > 10 km → Probablement Express (livraison urgente longue distance)
  /// - ≤ 10 km → Standard
  static DeliveryMode _inferMode({
    double? distanceKm,
    String? explicitMode,
  }) {
    // Si le backend fournit un mode explicite
    if (explicitMode != null) {
      if (explicitMode.toLowerCase() == 'express') {
        return DeliveryMode.express;
      }
      return DeliveryMode.standard;
    }

    // Sinon, inférer depuis la distance
    if (distanceKm != null && distanceKm > 10) {
      return DeliveryMode.express;
    }

    // Par défaut: Standard
    return DeliveryMode.standard;
  }

  /// Mappe le status backend → frontend
  ///
  /// Backend peut utiliser:
  /// - PENDING, pending
  /// - ACCEPTED, accepted
  /// - PICKUP_IN_PROGRESS, pickupInProgress
  /// - PICKED_UP, pickedUp
  /// - DELIVERY_IN_PROGRESS, deliveryInProgress
  /// - DELIVERED, delivered
  /// - CANCELLED, cancelled
  static DeliveryStatus _mapStatus(String backendStatus) {
    final normalized = backendStatus.toLowerCase().replaceAll('_', '');

    switch (normalized) {
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
        // Fallback sur pending si status inconnu
        return DeliveryStatus.pending;
    }
  }

  /// Convertit un status frontend → backend
  static String _statusToBackend(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.accepted:
        return 'accepted';
      case DeliveryStatus.pickupInProgress:
        return 'pickupInProgress';
      case DeliveryStatus.pickedUp:
        return 'pickedUp';
      case DeliveryStatus.deliveryInProgress:
        return 'deliveryInProgress';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Convertit une liste de livraisons backend → frontend
  static List<DeliveryModel> fromBackendList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromBackend(json as Map<String, dynamic>))
        .toList();
  }

  /// Vérifie si une livraison est "active" (en cours)
  ///
  /// Statuts actifs: accepted, pickupInProgress, pickedUp, deliveryInProgress
  static bool isActive(DeliveryModel delivery) {
    return [
      DeliveryStatus.accepted,
      DeliveryStatus.pickupInProgress,
      DeliveryStatus.pickedUp,
      DeliveryStatus.deliveryInProgress,
    ].contains(delivery.status);
  }

  /// Vérifie si une livraison est terminée (livrée ou annulée)
  static bool isCompleted(DeliveryModel delivery) {
    return delivery.status == DeliveryStatus.delivered ||
        delivery.status == DeliveryStatus.cancelled;
  }

  /// Vérifie si une livraison est disponible pour être acceptée
  static bool isAvailable(DeliveryModel delivery) {
    return delivery.status == DeliveryStatus.pending &&
        delivery.delivererId == null;
  }
}
