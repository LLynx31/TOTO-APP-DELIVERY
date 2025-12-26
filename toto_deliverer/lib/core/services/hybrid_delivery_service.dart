import '../../shared/models/delivery_model.dart';
import '../config/env_config.dart';
import 'delivery_service.dart';
import 'simulation_service.dart';

/// Service hybride pour gérer les livraisons
///
/// Route automatiquement vers SimulationService ou DeliveryService
/// selon la configuration EnvConfig.enableSimulationMode
///
/// Permet de basculer facilement entre simulation et API réelle
class HybridDeliveryService {
  final _deliveryService = DeliveryService();
  final _simulationService = SimulationService();

  /// Vérifie si le mode simulation est activé
  bool get isSimulationMode => EnvConfig.enableSimulationMode;

  /// Récupère les livraisons disponibles (statut: pending)
  ///
  /// Mode simulation: Retourne SimulationConfig.mockDeliveries filtrées
  /// Mode réel: GET /deliveries?status=pending
  Future<List<DeliveryModel>> getAvailableDeliveries() async {
    print('🔍 HybridDeliveryService: isSimulationMode = $isSimulationMode');

    if (isSimulationMode) {
      print('📱 Mode SIMULATION activé - Utilisation de données mockées');
      // En simulation, retourner les livraisons mockées disponibles (pending)
      return _simulationService
          .getSimulationDeliveries()
          .where((d) => d.status == DeliveryStatus.pending)
          .toList();
    }

    print('🌐 Mode API RÉELLE activé - Appel backend');
    return await _deliveryService.getAvailableDeliveries();
  }

  /// Récupère les livraisons actives du livreur
  ///
  /// Mode simulation: Retourne la livraison courante si elle existe
  /// Mode réel: GET /deliveries avec filtrage client-side
  Future<List<DeliveryModel>> getActiveDeliveries() async {
    if (isSimulationMode) {
      // En simulation, retourner la livraison courante si active
      final current = _simulationService.currentSimulatedDelivery;
      if (current != null &&
          [
            DeliveryStatus.accepted,
            DeliveryStatus.pickupInProgress,
            DeliveryStatus.pickedUp,
            DeliveryStatus.deliveryInProgress,
          ].contains(current.status)) {
        return [current];
      }
      return [];
    }

    return await _deliveryService.getActiveDeliveries();
  }

  /// Récupère les livraisons complétées (statut: delivered)
  ///
  /// Mode simulation: Retourne les livraisons mockées complétées
  /// Mode réel: GET /deliveries?status=delivered
  Future<List<DeliveryModel>> getCompletedDeliveries() async {
    if (isSimulationMode) {
      // En simulation, retourner les livraisons mockées livrées
      return _simulationService
          .getSimulationDeliveries()
          .where((d) => d.status == DeliveryStatus.delivered)
          .toList();
    }

    return await _deliveryService.getCompletedDeliveries();
  }

  /// Récupère une livraison par ID
  ///
  /// Mode simulation: Recherche dans SimulationConfig.mockDeliveries
  /// Mode réel: GET /deliveries/:id
  Future<DeliveryModel> getDeliveryById(String id) async {
    if (isSimulationMode) {
      // En simulation, chercher dans les livraisons mockées
      final delivery = _simulationService
          .getSimulationDeliveries()
          .firstWhere((d) => d.id == id);
      return delivery;
    }

    return await _deliveryService.getDeliveryById(id);
  }

  /// Accepte une livraison
  ///
  /// Mode simulation: Simule l'acceptation et met à jour le statut local
  /// Mode réel: POST /deliveries/:id/accept
  Future<DeliveryModel> acceptDelivery(String deliveryId) async {
    if (isSimulationMode) {
      // En simulation, trouver la livraison et la simuler
      final delivery = await getDeliveryById(deliveryId);
      return await _simulationService.simulateAcceptDelivery(delivery);
    }

    return await _deliveryService.acceptDelivery(deliveryId);
  }

  /// Démarre la phase de pickup (en route vers point A)
  ///
  /// Mode simulation: Met à jour le statut local
  /// Mode réel: PATCH /deliveries/:id avec status='pickupInProgress'
  Future<DeliveryModel> startPickup(String deliveryId) async {
    if (isSimulationMode) {
      final delivery = _simulationService.currentSimulatedDelivery!;
      final updated = await _simulationService.simulateStartToPickup(delivery);
      _simulationService.setCurrentDelivery(updated);
      return updated;
    }

    return await _deliveryService.startPickup(deliveryId);
  }

  /// Confirme le pickup avec scan QR code au point A
  ///
  /// Mode simulation: Valide le QR simulé et met à jour le statut
  /// Mode réel: POST /deliveries/:id/verify-qr avec type='pickup'
  Future<DeliveryModel> confirmPickup(
    String deliveryId,
    String qrCode,
  ) async {
    if (isSimulationMode) {
      // Vérifier le QR simulé
      final isValid = await _simulationService.simulateScanQRPickup(deliveryId);
      if (!isValid) {
        throw Exception('QR Code invalide pour le pickup');
      }

      final delivery = _simulationService.currentSimulatedDelivery!;
      final updated = await _simulationService.simulatePickup(delivery);
      _simulationService.setCurrentDelivery(updated);
      return updated;
    }

    return await _deliveryService.confirmPickup(deliveryId, qrCode);
  }

  /// Démarre la phase de livraison (en route vers point B)
  ///
  /// Mode simulation: Met à jour le statut local
  /// Mode réel: PATCH /deliveries/:id avec status='deliveryInProgress'
  Future<DeliveryModel> startDelivery(String deliveryId) async {
    if (isSimulationMode) {
      final delivery = _simulationService.currentSimulatedDelivery!;
      final updated = await _simulationService.simulateStartToDelivery(delivery);
      _simulationService.setCurrentDelivery(updated);
      return updated;
    }

    return await _deliveryService.startDelivery(deliveryId);
  }

  /// Confirme la livraison avec scan QR code au point B
  ///
  /// Mode simulation: Valide le QR simulé et met à jour le statut
  /// Mode réel: POST /deliveries/:id/verify-qr avec type='delivery'
  Future<DeliveryModel> confirmDelivery(
    String deliveryId,
    String qrCode,
  ) async {
    if (isSimulationMode) {
      // Vérifier le QR simulé
      final isValid = await _simulationService.simulateScanQRDelivery(deliveryId);
      if (!isValid) {
        throw Exception('QR Code invalide pour la livraison');
      }

      final delivery = _simulationService.currentSimulatedDelivery!;
      final updated = await _simulationService.simulateDelivery(delivery);
      _simulationService.setCurrentDelivery(updated);
      return updated;
    }

    return await _deliveryService.confirmDelivery(deliveryId, qrCode);
  }

  /// Confirme la livraison avec code 4 chiffres (fallback si pas d'app)
  ///
  /// Mode simulation: Valide le code manuel simulé
  /// Mode réel: POST /deliveries/:id/verify-qr avec delivery_code
  Future<DeliveryModel> confirmDeliveryWithCode(
    String deliveryId,
    String code,
  ) async {
    if (isSimulationMode) {
      // Vérifier le code manuel simulé
      final isValid = _simulationService.validateManualCode(deliveryId, code);
      if (!isValid) {
        throw Exception('Code de livraison invalide');
      }

      final delivery = _simulationService.currentSimulatedDelivery!;
      final updated = await _simulationService.simulateDelivery(delivery);
      _simulationService.setCurrentDelivery(updated);
      return updated;
    }

    return await _deliveryService.confirmDeliveryWithCode(deliveryId, code);
  }

  /// Annule une livraison avec raison
  ///
  /// Mode simulation: Met à jour le statut local
  /// Mode réel: POST /deliveries/:id/cancel
  Future<DeliveryModel> cancelDelivery(
    String deliveryId,
    String reason,
  ) async {
    if (isSimulationMode) {
      final delivery = _simulationService.currentSimulatedDelivery!;
      final updated = delivery.copyWith(status: DeliveryStatus.cancelled);
      _simulationService.setCurrentDelivery(updated);
      return updated;
    }

    return await _deliveryService.cancelDelivery(deliveryId, reason);
  }

  /// Note le client après livraison (rating bidirectionnel)
  ///
  /// Mode simulation: Simule l'envoi de la note
  /// Mode réel: POST /deliveries/:id/rate
  Future<void> rateCustomer(
    String deliveryId,
    int rating,
    String? comment,
  ) async {
    if (isSimulationMode) {
      await _simulationService.simulateSubmitRating(
        deliveryId,
        rating,
        comment,
      );
      return;
    }

    return await _deliveryService.rateCustomer(deliveryId, rating, comment);
  }

  /// Récupère la notation donnée pour une livraison
  ///
  /// Mode simulation: Retourne SimulationConfig.mockRatings
  /// Mode réel: GET /deliveries/:id/rating
  Future<Map<String, dynamic>?> getDeliveryRating(String deliveryId) async {
    if (isSimulationMode) {
      return _simulationService.getSimulatedRating(deliveryId);
    }

    return await _deliveryService.getDeliveryRating(deliveryId);
  }

  /// Vérifie si le livreur a déjà noté cette livraison
  ///
  /// Mode simulation: Toujours false (pas implémenté en simulation)
  /// Mode réel: GET /deliveries/:id/has-rated
  Future<bool> hasRatedDelivery(String deliveryId) async {
    if (isSimulationMode) {
      // En simulation, toujours permettre de noter
      return false;
    }

    return await _deliveryService.hasRatedDelivery(deliveryId);
  }

  /// Signale un problème pendant la livraison
  ///
  /// Mode simulation: Simule l'envoi du problème
  /// Mode réel: POST /deliveries/:id/problem
  Future<void> reportProblem(
    String deliveryId,
    String type,
    String description,
  ) async {
    if (isSimulationMode) {
      // En simulation, juste logger le problème
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    return await _deliveryService.reportProblem(deliveryId, type, description);
  }

  /// Récupère les QR codes d'une livraison
  ///
  /// Mode simulation: Retourne SimulationConfig.validQRCodes
  /// Mode réel: GET /deliveries/:id/qr-codes
  Future<Map<String, dynamic>> getQRCodes(String deliveryId) async {
    if (isSimulationMode) {
      // En simulation, retourner les codes mockés
      final qrCodes = {
        'qr_code_pickup': 'SIMULATION-PICKUP-$deliveryId',
        'qr_code_delivery': 'SIMULATION-DELIVERY-$deliveryId',
        'delivery_code': _simulationService.getValidManualCode(deliveryId) ?? '1234',
      };
      return qrCodes;
    }

    return await _deliveryService.getQRCodes(deliveryId);
  }

  /// Met à jour la position GPS du livreur
  ///
  /// Mode simulation: Pas d'action (pas de backend)
  /// Mode réel: POST /deliveries/:id/tracking
  Future<void> updateTracking(
    String deliveryId,
    double latitude,
    double longitude,
  ) async {
    if (isSimulationMode) {
      // En simulation, ne rien faire (pas de tracking backend)
      return;
    }

    return await _deliveryService.updateTracking(
      deliveryId,
      latitude,
      longitude,
    );
  }

  /// Récupère le service de simulation (pour accès aux méthodes spécifiques)
  SimulationService get simulationService => _simulationService;

  /// Récupère le service de livraison réel (pour accès direct si nécessaire)
  DeliveryService get deliveryService => _deliveryService;
}
