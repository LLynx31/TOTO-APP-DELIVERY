import '../../shared/models/models.dart';

/// Configuration pour le mode simulation
/// Contient les données mockées pour tester le workflow complet sans API
class SimulationConfig {
  // Active/désactive la fonctionnalité de simulation
  static const bool enableSimulation = true;

  // Liste des livraisons mockées pour la simulation
  static final List<DeliveryModel> mockDeliveries = [
    // SIM001: Livraison standard courte distance
    DeliveryModel(
      id: 'SIM001',
      customerId: 'CUST001',
      package: PackageModel(
        size: PackageSize.small,
        weight: 1.5,
        description: 'Documents importants',
      ),
      pickupAddress: AddressModel(
        address: 'Cocody Angré 8ème Tranche, Abidjan',
        latitude: 5.3599517,
        longitude: -3.9810350,
      ),
      deliveryAddress: AddressModel(
        address: 'Plateau, Rue du Commerce, Abidjan',
        latitude: 5.3250984,
        longitude: -4.0267813,
      ),
      mode: DeliveryMode.standard,
      status: DeliveryStatus.pending,
      price: 2500,
      hasInsurance: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),

    // SIM002: Livraison express longue distance avec assurance
    DeliveryModel(
      id: 'SIM002',
      customerId: 'CUST002',
      package: PackageModel(
        size: PackageSize.medium,
        weight: 5.0,
        description: 'Colis fragile - Électronique',
      ),
      pickupAddress: AddressModel(
        address: 'Yopougon Ananeraie, Abidjan',
        latitude: 5.3364447,
        longitude: -4.0890555,
      ),
      deliveryAddress: AddressModel(
        address: 'Bingerville, Route d\'Abatta, Abidjan',
        latitude: 5.3552416,
        longitude: -3.8897443,
      ),
      mode: DeliveryMode.express,
      status: DeliveryStatus.pending,
      price: 4500,
      hasInsurance: true,
      insuranceAmount: 50000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),

    // SIM003: Livraison standard avec photo du colis
    DeliveryModel(
      id: 'SIM003',
      customerId: 'CUST003',
      package: PackageModel(
        size: PackageSize.large,
        weight: 8.5,
        description: 'Carton de vêtements',
        photoUrl: 'https://example.com/package-photo.jpg',
      ),
      pickupAddress: AddressModel(
        address: 'Marcory Zone 4, Abidjan',
        latitude: 5.2849232,
        longitude: -3.9876543,
      ),
      deliveryAddress: AddressModel(
        address: 'Adjamé, Marché Gouro, Abidjan',
        latitude: 5.3514820,
        longitude: -4.0275394,
      ),
      mode: DeliveryMode.standard,
      status: DeliveryStatus.pending,
      price: 3200,
      hasInsurance: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  // Codes QR valides pour chaque livraison (simulation)
  static const Map<String, Map<String, String>> validQRCodes = {
    'SIM001': {
      'pickup': 'QR-SIM001-PICKUP-A',
      'delivery': 'QR-SIM001-DELIVERY-B',
    },
    'SIM002': {
      'pickup': 'QR-SIM002-PICKUP-A',
      'delivery': 'QR-SIM002-DELIVERY-B',
    },
    'SIM003': {
      'pickup': 'QR-SIM003-PICKUP-A',
      'delivery': 'QR-SIM003-DELIVERY-B',
    },
  };

  // Codes manuels valides pour la livraison (Point B uniquement)
  static const Map<String, String> validManualCodes = {
    'SIM001': '1234',
    'SIM002': '5678',
    'SIM003': '9012',
  };

  // Notes client pré-configurées pour chaque livraison
  static const List<Map<String, dynamic>> mockRatings = [
    {
      'deliveryId': 'SIM001',
      'rating': 5,
      'comment': 'Excellent service ! Livreur très professionnel et rapide.',
    },
    {
      'deliveryId': 'SIM002',
      'rating': 4,
      'comment': 'Bonne livraison, mais un peu de retard sur l\'heure prévue.',
    },
    {
      'deliveryId': 'SIM003',
      'rating': 5,
      'comment': 'Parfait ! Colis bien protégé et livré avec soin.',
    },
  ];

  // Durées moyennes de livraison (en minutes) pour chaque mode
  static const Map<DeliveryMode, int> averageDeliveryDuration = {
    DeliveryMode.standard: 90, // 1h30
    DeliveryMode.express: 35, // 35 minutes
  };
}
