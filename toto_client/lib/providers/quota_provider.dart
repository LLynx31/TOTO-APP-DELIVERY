import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quota_model.dart';
import '../services/quota_service.dart';

// Service provider
final quotaServiceProvider = Provider<QuotaService>((ref) {
  return QuotaService();
});

// Available packages state
class PackagesState {
  final List<QuotaPackageModel> packages;
  final bool isLoading;
  final String? error;

  PackagesState({
    this.packages = const [],
    this.isLoading = false,
    this.error,
  });

  PackagesState copyWith({
    List<QuotaPackageModel>? packages,
    bool? isLoading,
    String? error,
  }) {
    return PackagesState(
      packages: packages ?? this.packages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Packages notifier
class PackagesNotifier extends StateNotifier<PackagesState> {
  final QuotaService _quotaService;

  PackagesNotifier(this._quotaService) : super(PackagesState());

  // Charger les forfaits disponibles
  Future<void> loadPackages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final packages = await _quotaService.getAvailablePackages();
      state = state.copyWith(
        packages: packages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Rafraîchir
  Future<void> refresh() async {
    await loadPackages();
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Packages provider
final packagesProvider =
    StateNotifierProvider<PackagesNotifier, PackagesState>((ref) {
  final quotaService = ref.watch(quotaServiceProvider);
  return PackagesNotifier(quotaService);
});

// Client quotas state
class QuotasState {
  final List<ClientQuotaModel> quotas;
  final ClientQuotaModel? activeQuota;
  final bool isLoading;
  final String? error;

  QuotasState({
    this.quotas = const [],
    this.activeQuota,
    this.isLoading = false,
    this.error,
  });

  QuotasState copyWith({
    List<ClientQuotaModel>? quotas,
    ClientQuotaModel? activeQuota,
    bool? isLoading,
    String? error,
  }) {
    return QuotasState(
      quotas: quotas ?? this.quotas,
      activeQuota: activeQuota ?? this.activeQuota,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Vérifier si le client a des livraisons disponibles
  bool get hasAvailableDeliveries {
    if (activeQuota == null) return false;
    return activeQuota!.isActive &&
        activeQuota!.hasRemainingDeliveries &&
        !activeQuota!.isExpired;
  }

  // Obtenir le nombre de livraisons restantes
  int get remainingDeliveries {
    if (activeQuota == null) return 0;
    return activeQuota!.remainingDeliveries;
  }
}

// Quotas notifier
class QuotasNotifier extends StateNotifier<QuotasState> {
  final QuotaService _quotaService;

  QuotasNotifier(this._quotaService) : super(QuotasState());

  // Charger tous les quotas
  Future<void> loadQuotas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quotas = await _quotaService.getMyQuotas();
      final activeQuota = await _quotaService.getActiveQuota();

      state = state.copyWith(
        quotas: quotas,
        activeQuota: activeQuota,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Charger uniquement le quota actif
  Future<void> loadActiveQuota() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final activeQuota = await _quotaService.getActiveQuota();
      state = state.copyWith(
        activeQuota: activeQuota,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Acheter un forfait
  Future<bool> purchasePackage(String packageId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newQuota = await _quotaService.purchasePackage(packageId);

      // Ajouter le nouveau quota à la liste
      final updatedQuotas = [newQuota, ...state.quotas];

      state = state.copyWith(
        quotas: updatedQuotas,
        activeQuota: newQuota,
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

  // Rafraîchir
  Future<void> refresh() async {
    await loadQuotas();
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Vérifier si le client a des livraisons disponibles
  bool get hasAvailableDeliveries {
    final quota = state.activeQuota;
    if (quota == null) return false;
    return quota.isActive &&
        quota.hasRemainingDeliveries &&
        !quota.isExpired;
  }

  // Obtenir le nombre de livraisons restantes
  int get remainingDeliveries {
    final quota = state.activeQuota;
    if (quota == null) return 0;
    return quota.remainingDeliveries;
  }
}

// Quotas provider
final quotasProvider = StateNotifierProvider<QuotasNotifier, QuotasState>((ref) {
  final quotaService = ref.watch(quotaServiceProvider);
  return QuotasNotifier(quotaService);
});

// Quota history state
class QuotaHistoryState {
  final List<QuotaUsageHistoryModel> history;
  final bool isLoading;
  final String? error;

  QuotaHistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  QuotaHistoryState copyWith({
    List<QuotaUsageHistoryModel>? history,
    bool? isLoading,
    String? error,
  }) {
    return QuotaHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Quota history notifier
class QuotaHistoryNotifier extends StateNotifier<QuotaHistoryState> {
  final QuotaService _quotaService;
  final String quotaId;

  QuotaHistoryNotifier(this._quotaService, this.quotaId)
      : super(QuotaHistoryState());

  // Charger l'historique
  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _quotaService.getQuotaHistory(quotaId);
      state = state.copyWith(
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Rafraîchir
  Future<void> refresh() async {
    await loadHistory();
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Quota history provider family
final quotaHistoryProvider = StateNotifierProvider.family<QuotaHistoryNotifier,
    QuotaHistoryState, String>(
  (ref, quotaId) {
    final quotaService = ref.watch(quotaServiceProvider);
    final notifier = QuotaHistoryNotifier(quotaService, quotaId);
    notifier.loadHistory();
    return notifier;
  },
);
