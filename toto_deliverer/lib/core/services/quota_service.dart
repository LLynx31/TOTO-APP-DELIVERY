import '../../shared/models/quota_model.dart';
import '../adapters/quota_adapter.dart';
import '../config/api_config.dart';
import 'api_client.dart';

/// Service pour gérer les quotas avec intégration backend JWT-based
///
/// Utilise QuotaAdapter pour transformer les réponses backend
class QuotaService {
  final _apiClient = ApiClient();

  /// Récupère le quota actif du livreur authentifié
  ///
  /// Backend: GET /quotas/active (JWT-based)
  /// Le backend extrait l'ID du livreur depuis le token JWT
  /// Retourne null si aucun quota actif
  Future<QuotaModel?> getActiveQuota() async {
    try {
      final response = await _apiClient.get(ApiConfig.quotasActive);

      if (response.data == null) {
        return null;
      }

      final quotaData = response.data as Map<String, dynamic>;

      // Transformer avec QuotaAdapter (sans historique pour l'instant)
      final quota = QuotaAdapter.fromBackend(quotaData);

      // Charger l'historique séparément si le quota existe
      if (quota.id.isNotEmpty) {
        try {
          final history = await getQuotaHistory(quota.id);
          return quota.copyWith(purchaseHistory: history);
        } catch (e) {
          // Si l'historique échoue, retourner le quota sans historique
          return quota;
        }
      }

      return quota;
    } catch (e) {
      // Pas de quota actif ou erreur 404
      return null;
    }
  }

  /// Récupère tous les quotas du livreur authentifié
  ///
  /// Backend: GET /quotas/my-quotas (JWT-based)
  /// Inclut quotas actifs, expirés, et épuisés
  Future<List<QuotaModel>> getMyQuotas() async {
    final response = await _apiClient.get(ApiConfig.quotasMyQuotas);

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => QuotaAdapter.fromBackend(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les packs de quotas disponibles à l'achat
  ///
  /// Backend: GET /quotas/packages
  /// Retourne: [{ quota_type, deliveries, price, description }, ...]
  ///
  /// Exemple:
  /// ```json
  /// [
  ///   { "quota_type": "basic", "deliveries": 5, "price": 5000, "description": "Pack découverte" },
  ///   { "quota_type": "standard", "deliveries": 10, "price": 9500, "description": "Pack standard -5%" },
  ///   { "quota_type": "premium", "deliveries": 20, "price": 18000, "description": "Meilleure valeur -10%" }
  /// ]
  /// ```
  Future<List<Map<String, dynamic>>> getPackages() async {
    final response = await _apiClient.get(ApiConfig.quotasPackages);

    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  /// Achète un pack de quotas
  ///
  /// Backend: POST /quotas/purchase
  /// Le backend extrait l'ID du livreur depuis le token JWT
  ///
  /// Paramètres:
  /// - packType: Type de pack à acheter (pack5, pack10, pack20)
  /// - paymentMethod: Méthode de paiement (mobileMoney, bankTransfer, cash)
  /// - phoneNumber: Numéro de téléphone (optionnel, requis pour Mobile Money)
  ///
  /// Retourne le quota créé après achat
  Future<QuotaModel> purchaseQuota({
    required QuotaPackType packType,
    required PaymentMethod paymentMethod,
    String? phoneNumber,
  }) async {
    print('💰 QuotaService.purchaseQuota() appelé');
    print('📦 Pack type: ${packType.name}');
    print('💳 Payment method: ${paymentMethod.name}');
    print('📱 Phone number: $phoneNumber');

    // Utiliser QuotaAdapter pour construire la requête backend
    final requestData = QuotaAdapter.toPurchaseRequest(
      packType,
      paymentMethod,
    );

    // Ajouter le numéro de téléphone si fourni (requis pour Mobile Money)
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      requestData['phone_number'] = phoneNumber;
    }

    print('📤 Request data: $requestData');
    print('🌐 URL: ${ApiConfig.baseUrl}${ApiConfig.quotasPurchase}');

    try {
      final response = await _apiClient.post(
        ApiConfig.quotasPurchase,
        data: requestData,
      );

      print('✅ Purchase successful: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      // Le backend retourne le quota créé
      return QuotaAdapter.fromBackend(response.data as Map<String, dynamic>);
    } catch (e) {
      print('❌ Purchase error: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Récupère l'historique des transactions d'un quota spécifique
  ///
  /// Backend: GET /quotas/:quotaId/history
  /// Retourne toutes les transactions (purchase, usage, refund, expiration)
  ///
  /// Note: QuotaAdapter.buildPurchaseHistory() filtre uniquement les achats (type='purchase')
  Future<List<QuotaPurchase>> getQuotaHistory(String quotaId) async {
    final response = await _apiClient.get(
      ApiConfig.quotasHistory(quotaId),
    );

    final List<dynamic> transactions = response.data as List<dynamic>;

    // Utiliser QuotaAdapter pour construire l'historique d'achats
    // (filtre automatiquement les transactions de type 'purchase')
    return QuotaAdapter.buildPurchaseHistory(transactions);
  }

  /// Vérifie le statut d'une transaction de paiement
  ///
  /// Backend: GET /quotas/transactions/:transactionId/status
  /// Utile pour les paiements Mobile Money asynchrones
  ///
  /// Retourne:
  /// ```json
  /// {
  ///   "transaction_id": "t123",
  ///   "status": "pending" | "completed" | "failed",
  ///   "quota_id": "q456",
  ///   "payment_reference": "MTN-REF-..."
  /// }
  /// ```
  Future<Map<String, dynamic>> getTransactionStatus(String transactionId) async {
    final response = await _apiClient.get(
      ApiConfig.quotasTransactionStatus(transactionId),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Récupère le quota actif avec son historique complet
  ///
  /// Méthode de convenance qui combine getActiveQuota() et getQuotaHistory()
  /// Retourne null si aucun quota actif
  Future<QuotaModel?> getActiveQuotaWithHistory() async {
    final quota = await getActiveQuota();
    if (quota == null) return null;

    try {
      final history = await getQuotaHistory(quota.id);
      return quota.copyWith(purchaseHistory: history);
    } catch (e) {
      // Si l'historique échoue, retourner le quota sans historique
      return quota;
    }
  }

  /// Vérifie si le livreur a un quota actif suffisant
  ///
  /// Retourne true si le livreur a au moins 1 livraison disponible
  Future<bool> hasActiveQuota() async {
    final quota = await getActiveQuota();
    return quota != null && quota.hasQuota;
  }

  /// Vérifie si le quota du livreur est faible (≤ 2 livraisons restantes)
  ///
  /// Utile pour afficher des notifications de recharge
  Future<bool> isQuotaLow() async {
    final quota = await getActiveQuota();
    return quota != null && quota.isLow;
  }

  /// Récupère le nombre de livraisons restantes
  ///
  /// Retourne 0 si aucun quota actif
  Future<int> getRemainingDeliveries() async {
    final quota = await getActiveQuota();
    return quota?.remainingDeliveries ?? 0;
  }

  /// Récupère toutes les transactions d'achat du livreur
  ///
  /// Backend: GET /quotas/transactions
  /// Retourne l'historique complet des achats de quotas
  Future<List<QuotaPurchase>> getAllTransactions() async {
    try {
      print('📜 QuotaService: Fetching all transactions...');

      final response = await _apiClient.get(ApiConfig.quotasTransactions);

      print('✅ QuotaService: Response received');
      print('📦 Response data type: ${response.data.runtimeType}');

      final List<dynamic> transactions = response.data as List<dynamic>;

      print('📊 QuotaService: Found ${transactions.length} transactions');

      if (transactions.isNotEmpty) {
        print('🔍 Sample transaction: ${transactions[0]}');
      }

      // Transformer les transactions en QuotaPurchase
      final purchaseHistory = QuotaAdapter.buildPurchaseHistory(transactions);

      print('✅ QuotaService: Built ${purchaseHistory.length} purchase records');

      return purchaseHistory;
    } catch (e, stackTrace) {
      print('❌ Error fetching transactions: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }
}
