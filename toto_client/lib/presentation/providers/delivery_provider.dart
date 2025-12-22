import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/usecases/delivery/cancel_delivery_usecase.dart';
import '../../domain/usecases/delivery/create_delivery_usecase.dart';
import '../../domain/usecases/delivery/get_deliveries_usecase.dart';
import '../../domain/usecases/delivery/get_delivery_usecase.dart';
import '../../core/di/injection.dart' as di;
import 'auth_provider.dart';

/// État de la liste de livraisons
sealed class DeliveriesState {
  const DeliveriesState();
}

class DeliveriesInitial extends DeliveriesState {
  const DeliveriesInitial();
}

class DeliveriesLoading extends DeliveriesState {
  const DeliveriesLoading();
}

class DeliveriesLoaded extends DeliveriesState {
  final List<Delivery> deliveries;
  const DeliveriesLoaded(this.deliveries);
}

class DeliveriesError extends DeliveriesState {
  final String message;
  const DeliveriesError(this.message);
}

/// État d'une livraison unique
sealed class DeliveryState {
  const DeliveryState();
}

class DeliveryInitial extends DeliveryState {
  const DeliveryInitial();
}

class DeliveryLoading extends DeliveryState {
  const DeliveryLoading();
}

class DeliveryLoaded extends DeliveryState {
  final Delivery delivery;
  const DeliveryLoaded(this.delivery);
}

class DeliveryError extends DeliveryState {
  final String message;
  const DeliveryError(this.message);
}

/// Notifier pour la liste de livraisons
class DeliveriesNotifier extends StateNotifier<DeliveriesState> {
  final GetDeliveriesUsecase getDeliveriesUsecase;
  final CreateDeliveryUsecase createDeliveryUsecase;
  final CancelDeliveryUsecase cancelDeliveryUsecase;

  DeliveriesNotifier({
    required this.getDeliveriesUsecase,
    required this.createDeliveryUsecase,
    required this.cancelDeliveryUsecase,
  }) : super(const DeliveriesInitial());

  /// Charger les livraisons
  Future<void> loadDeliveries({DeliveryStatus? status}) async {
    state = const DeliveriesLoading();

    final result = await getDeliveriesUsecase(status: status);

    result.fold(
      (deliveries) => state = DeliveriesLoaded(deliveries),
      (error) => state = DeliveriesError(error),
    );
  }

  /// Créer une livraison
  Future<Delivery?> createDelivery(CreateDeliveryParams params) async {
    final result = await createDeliveryUsecase(params);

    Delivery? delivery;
    result.fold(
      (d) {
        delivery = d;
        // Recharger la liste
        loadDeliveries();
      },
      (error) {
        state = DeliveriesError(error);
      },
    );

    return delivery;
  }

  /// Annuler une livraison
  Future<bool> cancelDelivery(String id) async {
    final result = await cancelDeliveryUsecase(id);

    bool success = false;
    result.fold(
      (_) {
        success = true;
        // Recharger la liste
        loadDeliveries();
      },
      (error) {
        state = DeliveriesError(error);
      },
    );

    return success;
  }

  /// Rafraîchir la liste
  Future<void> refresh() async {
    await loadDeliveries();
  }
}

/// Notifier pour une livraison unique
class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final GetDeliveryUsecase getDeliveryUsecase;
  final CancelDeliveryUsecase cancelDeliveryUsecase;

  DeliveryNotifier({
    required this.getDeliveryUsecase,
    required this.cancelDeliveryUsecase,
  }) : super(const DeliveryInitial());

  /// Charger une livraison
  Future<void> loadDelivery(String id) async {
    state = const DeliveryLoading();

    final result = await getDeliveryUsecase(id);

    result.fold(
      (delivery) => state = DeliveryLoaded(delivery),
      (error) => state = DeliveryError(error),
    );
  }

  /// Annuler une livraison
  Future<bool> cancelDelivery(String id) async {
    final result = await cancelDeliveryUsecase(id);

    bool success = false;
    result.fold(
      (delivery) {
        success = true;
        state = DeliveryLoaded(delivery);
      },
      (error) {
        state = DeliveryError(error);
      },
    );

    return success;
  }

  /// Rafraîchir
  Future<void> refresh(String id) async {
    await loadDelivery(id);
  }
}

/// Providers
final deliveriesProvider = StateNotifierProvider<DeliveriesNotifier, DeliveriesState>((ref) {
  return DeliveriesNotifier(
    getDeliveriesUsecase: ref.watch(di.getDeliveriesUsecaseProvider),
    createDeliveryUsecase: ref.watch(di.createDeliveryUsecaseProvider),
    cancelDeliveryUsecase: ref.watch(di.cancelDeliveryUsecaseProvider),
  );
});

// Provider pour une livraison spécifique (family)
final deliveryProvider = StateNotifierProvider.family<DeliveryNotifier, DeliveryState, String>(
  (ref, deliveryId) {
    return DeliveryNotifier(
      getDeliveryUsecase: ref.watch(di.getDeliveryUsecaseProvider),
      cancelDeliveryUsecase: ref.watch(di.cancelDeliveryUsecaseProvider),
    );
  },
);
