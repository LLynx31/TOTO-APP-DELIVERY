import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/quota_service.dart';
import '../../../shared/models/quota_model.dart';

/// État des quotas avec types typés (QuotaModel)
class QuotaState {
  final QuotaModel? activeQuota;
  final List<QuotaPurchase> quotaHistory;
  final List<Map<String, dynamic>> availablePackages;
  final bool isLoading;
  final String? error;

  QuotaState({
    this.activeQuota,
    this.quotaHistory = const [],
    this.availablePackages = const [],
    this.isLoading = false,
    this.error,
  });

  QuotaState copyWith({
    QuotaModel? activeQuota,
    List<QuotaPurchase>? quotaHistory,
    List<Map<String, dynamic>>? availablePackages,
    bool? isLoading,
    String? error,
  }) {
    return QuotaState(
      activeQuota: activeQuota ?? this.activeQuota,
      quotaHistory: quotaHistory ?? this.quotaHistory,
      availablePackages: availablePackages ?? this.availablePackages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Vérifie si le livreur a des livraisons disponibles
  bool get hasAvailableDeliveries {
    return activeQuota != null && activeQuota!.hasQuota;
  }

  /// Nombre de livraisons restantes
  int get remainingDeliveries {
    return activeQuota?.remainingDeliveries ?? 0;
  }

  /// Vérifie si le quota est faible (≤ 2 livraisons restantes)
  bool get isQuotaLow {
    return activeQuota != null && activeQuota!.isLow;
  }
}

/// Notifier pour gérer les quotas avec QuotaService (JWT-based)
///
/// Le backend extrait l'ID du livreur depuis le token JWT
class QuotaNotifier extends StateNotifier<QuotaState> {
  final QuotaService _quotaService = QuotaService();

  QuotaNotifier() : super(QuotaState());

  /// Récupère le quota actif du livreur authentifié
  ///
  /// Backend: GET /quotas/active (JWT-based)
  Future<void> loadActiveQuota() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quota = await _quotaService.getActiveQuota();
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

  /// Récupère les packs de quotas disponibles à l'achat
  ///
  /// Backend: GET /quotas/packages
  Future<void> loadAvailablePackages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final packages = await _quotaService.getPackages();
      state = state.copyWith(
        availablePackages: packages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Achète un pack de quotas
  ///
  /// Backend: POST /quotas/purchase (JWT-based)
  ///
  /// Paramètres:
  /// - packType: Type de pack (pack5, pack10, pack20)
  /// - paymentMethod: Méthode de paiement (mobileMoney, bankTransfer, cash)
  /// - phoneNumber: Numéro pour Mobile Money (optionnel)
  Future<void> purchaseQuota({
    required QuotaPackType packType,
    required PaymentMethod paymentMethod,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quota = await _quotaService.purchaseQuota(
        packType: packType,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
      );

      // Mettre à jour le quota actif avec le nouveau quota
      state = state.copyWith(
        activeQuota: quota,
        isLoading: false,
      );

      // Recharger l'historique
      await loadQuotaHistory();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Récupère l'historique des achats de quotas
  ///
  /// Backend: GET /quotas/:quotaId/history
  /// Nécessite qu'un quota actif soit chargé
  Future<void> loadQuotaHistory() async {
    // Vérifier qu'il y a un quota actif
    if (state.activeQuota == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _quotaService.getQuotaHistory(
        state.activeQuota!.id,
      );
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

  /// Vérifie si le livreur a un quota actif
  ///
  /// Méthode de convenance, équivalent à state.hasAvailableDeliveries
  Future<bool> hasActiveQuota() async {
    return await _quotaService.hasActiveQuota();
  }

  /// Récupère le nombre de livraisons restantes
  ///
  /// Méthode de convenance
  Future<int> getRemainingDeliveries() async {
    return await _quotaService.getRemainingDeliveries();
  }

  /// Vérifie le statut d'une transaction de paiement
  ///
  /// Utile pour les paiements Mobile Money asynchrones
  Future<Map<String, dynamic>> getTransactionStatus(String transactionId) async {
    return await _quotaService.getTransactionStatus(transactionId);
  }

  /// Recharge toutes les données de quotas (quota actif + historique + packages)
  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Charger le quota actif
      await loadActiveQuota();

      // Charger l'historique si quota actif existe
      if (state.activeQuota != null) {
        await loadQuotaHistory();
      }

      // Charger les packages disponibles
      await loadAvailablePackages();

      state = state.copyWith(isLoading: false);
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
