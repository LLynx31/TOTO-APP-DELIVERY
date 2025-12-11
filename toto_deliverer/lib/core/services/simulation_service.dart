import '../config/simulation_config.dart';
import '../../shared/models/models.dart';

/// Service singleton pour gérer le mode simulation
/// Permet de tester le workflow complet sans API ni scan QR réel
class SimulationService {
  // Singleton pattern
  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal();

  // État du mode simulation
  bool _isSimulationMode = false;

  // Livraison actuellement en cours de simulation
  DeliveryModel? _currentSimulatedDelivery;

  // Getters
  bool get isSimulationMode => _isSimulationMode;
  DeliveryModel? get currentSimulatedDelivery => _currentSimulatedDelivery;

  /// Active/désactive le mode simulation
  void toggleSimulation() {
    _isSimulationMode = !_isSimulationMode;
    if (!_isSimulationMode) {
      // Reset la livraison en cours si on désactive la simulation
      _currentSimulatedDelivery = null;
    }
  }

  /// Définit le mode simulation (on/off)
  void setSimulationMode(bool enabled) {
    _isSimulationMode = enabled;
    if (!_isSimulationMode) {
      _currentSimulatedDelivery = null;
    }
  }

  /// Retourne la liste des livraisons mockées pour la simulation
  List<DeliveryModel> getSimulationDeliveries() {
    if (!_isSimulationMode) {
      return [];
    }
    return SimulationConfig.mockDeliveries;
  }

  /// Définit la livraison actuellement en cours de simulation
  void setCurrentDelivery(DeliveryModel delivery) {
    _currentSimulatedDelivery = delivery;
  }

  /// Simule le scan d'un code QR au point de pickup (Point A)
  /// Retourne true si le scan est réussi, false sinon
  Future<bool> simulateScanQRPickup(String deliveryId) async {
    // Simule un délai de scan
    await Future.delayed(const Duration(milliseconds: 800));

    // Vérifie si le code QR est valide
    final qrCodes = SimulationConfig.validQRCodes[deliveryId];
    if (qrCodes == null || qrCodes['pickup'] == null) {
      return false;
    }

    return true;
  }

  /// Simule le scan d'un code QR au point de livraison (Point B)
  /// Retourne true si le scan est réussi, false sinon
  Future<bool> simulateScanQRDelivery(String deliveryId) async {
    // Simule un délai de scan
    await Future.delayed(const Duration(milliseconds: 800));

    // Vérifie si le code QR est valide
    final qrCodes = SimulationConfig.validQRCodes[deliveryId];
    if (qrCodes == null || qrCodes['delivery'] == null) {
      return false;
    }

    return true;
  }

  /// Valide un code manuel au point de livraison (Point B)
  /// Retourne true si le code est correct, false sinon
  bool validateManualCode(String deliveryId, String code) {
    final validCode = SimulationConfig.validManualCodes[deliveryId];
    if (validCode == null) {
      return false;
    }

    return code == validCode;
  }

  /// Récupère la note pré-configurée pour une livraison
  /// Retourne null si aucune note n'est configurée
  Map<String, dynamic>? getSimulatedRating(String deliveryId) {
    try {
      return SimulationConfig.mockRatings.firstWhere(
        (rating) => rating['deliveryId'] == deliveryId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Récupère le code manuel valide pour une livraison (pour affichage debug)
  String? getValidManualCode(String deliveryId) {
    return SimulationConfig.validManualCodes[deliveryId];
  }

  /// Simule l'acceptation d'une course
  Future<DeliveryModel> simulateAcceptDelivery(DeliveryModel delivery) async {
    // Simule un délai d'acceptation
    await Future.delayed(const Duration(milliseconds: 500));

    // Met à jour le statut et définit comme livraison courante
    final updatedDelivery = delivery.copyWith(
      status: DeliveryStatus.accepted,
      acceptedAt: DateTime.now(),
    );

    _currentSimulatedDelivery = updatedDelivery;
    return updatedDelivery;
  }

  /// Simule le démarrage vers le point A (pickup)
  Future<DeliveryModel> simulateStartToPickup(DeliveryModel delivery) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return delivery.copyWith(
      status: DeliveryStatus.pickupInProgress,
    );
  }

  /// Simule la récupération du colis au point A
  Future<DeliveryModel> simulatePickup(DeliveryModel delivery) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return delivery.copyWith(
      status: DeliveryStatus.pickedUp,
      pickedUpAt: DateTime.now(),
    );
  }

  /// Simule le démarrage vers le point B (delivery)
  Future<DeliveryModel> simulateStartToDelivery(DeliveryModel delivery) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return delivery.copyWith(
      status: DeliveryStatus.deliveryInProgress,
    );
  }

  /// Simule la livraison du colis au point B
  Future<DeliveryModel> simulateDelivery(DeliveryModel delivery) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return delivery.copyWith(
      status: DeliveryStatus.delivered,
      deliveredAt: DateTime.now(),
    );
  }

  /// Simule la soumission d'une note client
  Future<bool> simulateSubmitRating(
    String deliveryId,
    int rating,
    String? comment,
  ) async {
    // Simule un délai d'envoi
    await Future.delayed(const Duration(milliseconds: 600));

    // En mode simulation, toujours réussir
    return true;
  }

  /// Reset complet du service (appelé au redémarrage de l'app)
  void reset() {
    _isSimulationMode = false;
    _currentSimulatedDelivery = null;
  }
}
