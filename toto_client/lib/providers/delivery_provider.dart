import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_model.dart';
import '../services/delivery_service.dart';

// Service provider
final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService();
});

// Delivery list state
class DeliveryListState {
  final List<DeliveryModel> deliveries;
  final bool isLoading;
  final String? error;

  DeliveryListState({
    this.deliveries = const [],
    this.isLoading = false,
    this.error,
  });

  DeliveryListState copyWith({
    List<DeliveryModel>? deliveries,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryListState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Delivery list notifier
class DeliveryListNotifier extends StateNotifier<DeliveryListState> {
  final DeliveryService _deliveryService;

  DeliveryListNotifier(this._deliveryService) : super(DeliveryListState());

  // Charger toutes les livraisons
  Future<void> loadDeliveries({
    DeliveryStatus? status,
    int? limit,
    int? offset,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deliveries = await _deliveryService.getMyDeliveries(
        status: status,
        limit: limit,
        offset: offset,
      );

      state = state.copyWith(
        deliveries: deliveries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Rafraîchir la liste
  Future<void> refresh({DeliveryStatus? status}) async {
    await loadDeliveries(status: status);
  }

  // Ajouter une nouvelle livraison
  void addDelivery(DeliveryModel delivery) {
    state = state.copyWith(
      deliveries: [delivery, ...state.deliveries],
    );
  }

  // Mettre à jour une livraison
  void updateDelivery(DeliveryModel delivery) {
    final updatedList = state.deliveries.map((d) {
      return d.id == delivery.id ? delivery : d;
    }).toList();

    state = state.copyWith(deliveries: updatedList);
  }

  // Supprimer une livraison
  void removeDelivery(String deliveryId) {
    final updatedList = state.deliveries
        .where((d) => d.id != deliveryId)
        .toList();

    state = state.copyWith(deliveries: updatedList);
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Delivery list provider
final deliveryListProvider =
    StateNotifierProvider<DeliveryListNotifier, DeliveryListState>((ref) {
  final deliveryService = ref.watch(deliveryServiceProvider);
  return DeliveryListNotifier(deliveryService);
});

// Single delivery state
class DeliveryState {
  final DeliveryModel? delivery;
  final bool isLoading;
  final String? error;

  DeliveryState({
    this.delivery,
    this.isLoading = false,
    this.error,
  });

  DeliveryState copyWith({
    DeliveryModel? delivery,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryState(
      delivery: delivery ?? this.delivery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Single delivery notifier
class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final DeliveryService _deliveryService;

  DeliveryNotifier(this._deliveryService) : super(DeliveryState());

  // Charger une livraison par ID
  Future<void> loadDelivery(String deliveryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.getDeliveryById(deliveryId);
      state = state.copyWith(
        delivery: delivery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Créer une nouvelle livraison
  Future<bool> createDelivery(CreateDeliveryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.createDelivery(request);
      state = state.copyWith(
        delivery: delivery,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Annuler une livraison
  Future<bool> cancelDelivery(String deliveryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _deliveryService.cancelDelivery(deliveryId);
      state = state.copyWith(
        delivery: delivery,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Mettre à jour la livraison actuelle
  void updateCurrentDelivery(DeliveryModel delivery) {
    state = state.copyWith(delivery: delivery);
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Réinitialiser
  void reset() {
    state = DeliveryState();
  }
}

// Single delivery provider family (pour créer une instance par deliveryId)
final deliveryProvider =
    StateNotifierProvider.family<DeliveryNotifier, DeliveryState, String?>(
  (ref, deliveryId) {
    final deliveryService = ref.watch(deliveryServiceProvider);
    final notifier = DeliveryNotifier(deliveryService);
    if (deliveryId != null) {
      notifier.loadDelivery(deliveryId);
    }
    return notifier;
  },
);
