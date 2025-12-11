import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/quota_service.dart';

class QuotaState {
  final Map<String, dynamic>? activeQuota;
  final List<dynamic> quotaHistory;
  final bool isLoading;
  final String? error;

  QuotaState({
    this.activeQuota,
    this.quotaHistory = const [],
    this.isLoading = false,
    this.error,
  });

  QuotaState copyWith({
    Map<String, dynamic>? activeQuota,
    List<dynamic>? quotaHistory,
    bool? isLoading,
    String? error,
  }) {
    return QuotaState(
      activeQuota: activeQuota ?? this.activeQuota,
      quotaHistory: quotaHistory ?? this.quotaHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Vérifier si le livreur a des livraisons disponibles
  bool get hasAvailableDeliveries {
    if (activeQuota == null) return false;
    final remainingDeliveries = activeQuota!['remaining_deliveries'] as int?;
    final expiresAt = activeQuota!['expires_at'] as String?;

    if (remainingDeliveries == null || expiresAt == null) return false;

    final isExpired = DateTime.parse(expiresAt).isBefore(DateTime.now());
    return remainingDeliveries > 0 && !isExpired;
  }

  // Nombre de livraisons restantes
  int get remainingDeliveries {
    if (activeQuota == null) return 0;
    return activeQuota!['remaining_deliveries'] as int? ?? 0;
  }
}

class QuotaNotifier extends StateNotifier<QuotaState> {
  final QuotaService _quotaService = QuotaService();

  QuotaNotifier() : super(QuotaState());

  // Récupérer le quota actif
  Future<void> loadActiveQuota(String delivererId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quota = await _quotaService.getActiveQuota(delivererId);
      state = state.copyWith(
        activeQuota: quota,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Acheter un pack de quotas
  Future<void> purchaseQuota({
    required String delivererId,
    required String packageId,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _quotaService.purchaseQuota(
        delivererId: delivererId,
        packageId: packageId,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
      );

      // Recharger le quota actif
      await loadActiveQuota(delivererId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Récupérer l'historique
  Future<void> loadQuotaHistory(String delivererId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _quotaService.getQuotaHistory(delivererId);
      state = state.copyWith(
        quotaHistory: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final quotaProvider = StateNotifierProvider<QuotaNotifier, QuotaState>((ref) {
  return QuotaNotifier();
});
