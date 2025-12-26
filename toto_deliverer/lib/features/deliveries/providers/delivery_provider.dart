import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/hybrid_delivery_service.dart';
import '../../../shared/models/delivery_model.dart';

/// État des livraisons avec types typés (DeliveryModel)
class DeliveryState {
  final List<DeliveryModel> availableDeliveries;
  final List<DeliveryModel> activeDeliveries;
  final List<DeliveryModel> completedDeliveries;
  final DeliveryModel? currentDelivery;
  final bool isLoading;
  final String? error;

  DeliveryState({
    this.availableDeliveries = const [],
    this.activeDeliveries = const [],
    this.completedDeliveries = const [],
    this.currentDelivery,
    this.isLoading = false,
    this.error,
  });

  DeliveryState copyWith({
    List<DeliveryModel>? availableDeliveries,
    List<DeliveryModel>? activeDeliveries,
    List<DeliveryModel>? completedDeliveries,
    DeliveryModel? currentDelivery,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryState(
      availableDeliveries: availableDeliveries ?? this.availableDeliveries,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      currentDelivery: currentDelivery ?? this.currentDelivery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer les livraisons avec HybridDeliveryService
///
/// Utilise automatiquement le mode simulation ou réel selon EnvConfig.enableSimulationMode
class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final HybridDeliveryService _deliveryService = HybridDeliveryService();

  DeliveryNotifier() : super(DeliveryState());

  // Récupérer les livraisons disponibles
  Future<void> loadAvailableDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deliveries = await _deliveryService.getAvailableDeliveries();
      state = state.copyWith(
        availableDeliveries: deliveries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Récupérer les livraisons actives
  Future<void> loadActiveDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deliveries = await _deliveryService.getActiveDeliveries();
      state = state.copyWith(
        activeDeliveries: deliveries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Récupérer les livraisons complétées
  Future<void> loadCompletedDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deliveries = await _deliveryService.getCompletedDeliveries();
      state = state.copyWith(
        completedDeliveries: deliveries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Récupérer une livraison par ID
  Future<void> loadDeliveryById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.getDeliveryById(id);
      state = state.copyWith(
        currentDelivery: delivery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Accepter une livraison
  Future<void> acceptDelivery(String deliveryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.acceptDelivery(deliveryId);
      state = state.copyWith(
        currentDelivery: delivery,
        isLoading: false,
      );
      // Recharger les listes
      await loadAvailableDeliveries();
      await loadActiveDeliveries();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Démarrer le pickup
  Future<void> startPickup(String deliveryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.startPickup(deliveryId);
      state = state.copyWith(
        currentDelivery: delivery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Confirmer le pickup
  Future<void> confirmPickup(String deliveryId, String qrCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.confirmPickup(deliveryId, qrCode);
      state = state.copyWith(
        currentDelivery: delivery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Démarrer la livraison
  Future<void> startDelivery(String deliveryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.startDelivery(deliveryId);
      state = state.copyWith(
        currentDelivery: delivery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Confirmer la livraison
  Future<void> confirmDelivery(String deliveryId, String qrCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.confirmDelivery(deliveryId, qrCode);
      state = state.copyWith(
        currentDelivery: delivery,
        isLoading: false,
      );
      // Recharger les listes
      await loadActiveDeliveries();
      await loadCompletedDeliveries();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Annuler une livraison
  Future<void> cancelDelivery(String deliveryId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.cancelDelivery(deliveryId, reason);
      state = state.copyWith(
        currentDelivery: delivery,
        isLoading: false,
      );
      // Recharger les listes
      await loadActiveDeliveries();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Noter le client
  Future<void> rateCustomer(
    String deliveryId,
    int rating,
    String? comment,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _deliveryService.rateCustomer(deliveryId, rating, comment);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Signaler un problème
  Future<void> reportProblem(
    String deliveryId,
    String type,
    String description,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _deliveryService.reportProblem(deliveryId, type, description);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  return DeliveryNotifier();
});
