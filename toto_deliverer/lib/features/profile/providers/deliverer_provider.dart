import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/deliverer_service.dart';
import '../../../shared/models/deliverer_model.dart';

class DelivererState {
  final bool isLoading;
  final DelivererModel? deliverer;
  final DelivererStats? stats;
  final DailyStats? dailyStats;
  final EarningsData? earnings;
  final String? error;

  DelivererState({
    this.isLoading = false,
    this.deliverer,
    this.stats,
    this.dailyStats,
    this.earnings,
    this.error,
  });

  DelivererState copyWith({
    bool? isLoading,
    DelivererModel? deliverer,
    DelivererStats? stats,
    DailyStats? dailyStats,
    EarningsData? earnings,
    String? error,
  }) {
    return DelivererState(
      isLoading: isLoading ?? this.isLoading,
      deliverer: deliverer ?? this.deliverer,
      stats: stats ?? this.stats,
      dailyStats: dailyStats ?? this.dailyStats,
      earnings: earnings ?? this.earnings,
      error: error,
    );
  }
}

class DelivererNotifier extends StateNotifier<DelivererState> {
  final DelivererService _delivererService = DelivererService();

  DelivererNotifier() : super(DelivererState());

  /// Charger le profil du livreur depuis l'API
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _delivererService.init();
      final deliverer = await _delivererService.getProfile();

      state = state.copyWith(
        isLoading: false,
        deliverer: deliverer,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Charger les statistiques du livreur
  Future<void> loadStats() async {
    try {
      await _delivererService.init();
      final stats = await _delivererService.getStats();

      state = state.copyWith(stats: stats);
    } catch (e) {
      // Silently fail for stats, not critical
      print('⚠️ Erreur chargement stats: $e');
    }
  }

  /// Mettre à jour le profil
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? photoUrl,
    String? vehicleType,
    String? licensePlate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _delivererService.init();
      final updatedDeliverer = await _delivererService.updateProfile(
        fullName: fullName,
        email: email,
        photoUrl: photoUrl,
        vehicleType: vehicleType,
        licensePlate: licensePlate,
      );

      state = state.copyWith(
        isLoading: false,
        deliverer: updatedDeliverer,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Mettre à jour la disponibilité
  Future<bool> updateAvailability(bool isAvailable) async {
    try {
      await _delivererService.init();
      final newAvailability = await _delivererService.updateAvailability(isAvailable);

      // Mettre à jour le state local
      if (state.deliverer != null) {
        state = state.copyWith(
          deliverer: state.deliverer!.copyWith(isOnline: newAvailability),
        );
      }

      return newAvailability;
    } catch (e) {
      rethrow;
    }
  }

  /// Charger les statistiques journalières
  Future<void> loadDailyStats() async {
    try {
      await _delivererService.init();
      final dailyStats = await _delivererService.getDailyStats();

      state = state.copyWith(dailyStats: dailyStats);
    } catch (e) {
      // Silently fail for daily stats, not critical
      print('⚠️ Erreur chargement stats journalières: $e');
    }
  }

  /// Charger les gains
  Future<void> loadEarnings({String period = 'today'}) async {
    try {
      await _delivererService.init();
      final earnings = await _delivererService.getEarnings(period: period);

      state = state.copyWith(earnings: earnings);
    } catch (e) {
      // Silently fail for earnings, not critical
      print('⚠️ Erreur chargement gains: $e');
    }
  }
}

final delivererProvider = StateNotifierProvider<DelivererNotifier, DelivererState>((ref) {
  return DelivererNotifier();
});
