import 'package:toto_deliverer/core/adapters/base_adapter.dart';
import 'package:toto_deliverer/shared/models/quota_model.dart';

/// Adapter pour transformer les quotas backend → frontend
///
/// Mapping Backend (snake_case) → Frontend (camelCase):
/// - user_id → delivererId
/// - total_deliveries → totalPurchased
/// - remaining_deliveries → remainingDeliveries
/// - purchased_at → lastUpdated
/// - quota_type (basic/standard/premium) → packType (basic/standard/premium)
class QuotaAdapter {
  /// Convertit un quota backend en modèle frontend
  ///
  /// Exemple backend:
  /// ```json
  /// {
  ///   "id": "q123",
  ///   "user_id": "u456",
  ///   "quota_type": "standard",
  ///   "total_deliveries": 50,
  ///   "remaining_deliveries": 35,
  ///   "price_paid": 35000,
  ///   "purchased_at": "2024-01-01T10:00:00Z",
  ///   "expires_at": "2024-03-01T10:00:00Z",
  ///   "is_active": true
  /// }
  /// ```
  static QuotaModel fromBackend(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    // ApiClient transforme snake_case → camelCase, donc vérifier les deux
    final delivererId = json['userId'] as String? ??
                        json['user_id'] as String? ?? '';

    // Le backend stocke total_deliveries (quota acheté)
    // ApiClient le transforme en totalDeliveries
    final totalPurchased = BaseAdapter.toInt(json['totalDeliveries']) ??
                          BaseAdapter.toInt(json['total_deliveries']) ?? 0;
    final remainingDeliveries =
        BaseAdapter.toInt(json['remainingDeliveries']) ??
        BaseAdapter.toInt(json['remaining_deliveries']) ?? 0;

    // Pour lastUpdated, utiliser purchased_at ou updated_at
    final lastUpdated = BaseAdapter.parseDate(json['purchasedAt']) ??
        BaseAdapter.parseDate(json['purchased_at']) ??
        BaseAdapter.parseDate(json['updatedAt']) ??
        BaseAdapter.parseDate(json['updated_at']) ??
        DateTime.now();

    // purchaseHistory doit être construit séparément via buildPurchaseHistory()
    // car il nécessite un appel API supplémentaire à /quotas/:id/history

    return QuotaModel(
      id: id,
      delivererId: delivererId,
      remainingDeliveries: remainingDeliveries,
      totalPurchased: totalPurchased,
      lastUpdated: lastUpdated,
      purchaseHistory: [], // À remplir via buildPurchaseHistory()
    );
  }

  /// Construit l'historique d'achats depuis les transactions backend
  ///
  /// Filtre uniquement les transactions de type 'purchase'
  ///
  /// Exemple backend transaction:
  /// ```json
  /// {
  ///   "id": "t123",
  ///   "quota_id": "q456",
  ///   "transaction_type": "purchase",
  ///   "amount": 50,
  ///   "balance_before": 0,
  ///   "balance_after": 50,
  ///   "description": "Achat pack standard",
  ///   "created_at": "2024-01-01T10:00:00Z",
  ///   "price_paid": 35000,
  ///   "quota_type": "standard"
  /// }
  /// ```
  static List<QuotaPurchase> buildPurchaseHistory(List<dynamic> transactions) {
    final purchases = <QuotaPurchase>[];

    print('🔄 QuotaAdapter: Building purchase history from ${transactions.length} transactions');

    for (final transaction in transactions) {
      final json = transaction as Map<String, dynamic>;

      // Filtrer uniquement les achats (pas usage/refund/expiration)
      // ApiClient transforme snake_case → camelCase, donc vérifier les deux
      final transactionType = json['transactionType'] as String? ??
                             json['transaction_type'] as String?;

      print('📝 Transaction type: $transactionType');

      if (transactionType != 'purchase') {
        print('⏭️ Skipping non-purchase transaction: $transactionType');
        continue;
      }

      final id = json['id'] as String;
      final deliveries = BaseAdapter.toInt(json['amount']) ?? 0;
      // ApiClient transforme price_paid → pricePaid
      final price = BaseAdapter.toDouble(json['pricePaid']) ??
                   BaseAdapter.toDouble(json['price_paid']) ?? 0.0;
      // ApiClient transforme created_at → createdAt
      final purchasedAt = BaseAdapter.parseDate(json['createdAt']) ??
          BaseAdapter.parseDate(json['created_at']) ??
          DateTime.now();

      // Inférer le pack type depuis quota_type ou amount
      // ApiClient transforme quota_type → quotaType
      final quotaType = json['quotaType'] as String? ??
                       json['quota_type'] as String?;
      final packType = _inferPackType(quotaType, deliveries);

      // Méthode de paiement (peut ne pas être dans le backend)
      // ApiClient transforme payment_method → paymentMethod
      final paymentMethodStr = json['paymentMethod'] as String? ??
                              json['payment_method'] as String?;
      final paymentMethod = _mapPaymentMethod(paymentMethodStr);

      // isProcessed: transaction créée = processed
      final isProcessed = true;

      print('✅ Adding purchase: $deliveries deliveries for $price FCFA');

      purchases.add(QuotaPurchase(
        id: id,
        deliveries: deliveries,
        price: price,
        packType: packType,
        paymentMethod: paymentMethod,
        purchasedAt: purchasedAt,
        isProcessed: isProcessed,
      ));
    }

    print('✅ Built ${purchases.length} purchase records');

    return purchases;
  }

  /// Infère le QuotaPackType depuis le quota_type backend ou le nombre de livraisons
  ///
  /// Backend quota_type mapping:
  /// - basic → basic (10 livraisons)
  /// - standard → standard (50 livraisons)
  /// - premium → premium (100 livraisons)
  /// - custom → inférer depuis le nombre
  static QuotaPackType _inferPackType(String? quotaType, int deliveries) {
    if (quotaType != null) {
      return QuotaPackType.fromBackend(quotaType);
    }

    // Inférer depuis le nombre de livraisons
    if (deliveries <= 10) {
      return QuotaPackType.basic;
    } else if (deliveries <= 50) {
      return QuotaPackType.standard;
    } else {
      return QuotaPackType.premium;
    }
  }

  /// Mappe la méthode de paiement backend → frontend
  ///
  /// Backend peut fournir:
  /// - orange_money → orangeMoney
  /// - mtn_money → mtnMoney
  /// - moov_money → moovMoney
  /// - wave → wave
  static PaymentMethod _mapPaymentMethod(String? backendMethod) {
    return PaymentMethod.fromBackend(backendMethod);
  }

  /// Crée la requête d'achat de quota pour le backend
  ///
  /// Exemple output:
  /// ```json
  /// {
  ///   "quota_type": "standard",
  ///   "payment_method": "orange_money",
  ///   "payment_reference": "SIM-..."
  /// }
  /// ```
  static Map<String, dynamic> toPurchaseRequest(
    QuotaPackType packType,
    PaymentMethod paymentMethod,
  ) {
    // Générer une référence de paiement simulée
    final paymentReference = 'SIM-${DateTime.now().millisecondsSinceEpoch}';

    return {
      'quota_type': packType.backendName,
      'payment_method': paymentMethod.backendName,
      'payment_reference': paymentReference,
    };
  }

  /// Convertit un modèle frontend en données backend (rarement utilisé)
  static Map<String, dynamic> toBackend(QuotaModel model) {
    return {
      'id': model.id,
      'user_id': model.delivererId,
      'remaining_deliveries': model.remainingDeliveries,
      'total_deliveries': model.totalPurchased,
      'updated_at': model.lastUpdated.toIso8601String(),
    };
  }

  /// Vérifie si un quota est actif (a des livraisons restantes)
  static bool isActive(QuotaModel quota) {
    return quota.remainingDeliveries > 0;
  }

  /// Vérifie si un quota est faible (≤ 2 livraisons restantes)
  static bool isLow(QuotaModel quota) {
    return quota.remainingDeliveries > 0 && quota.remainingDeliveries <= 2;
  }

  /// Calcule le pourcentage de quota restant
  static double getUsagePercentage(QuotaModel quota) {
    if (quota.totalPurchased == 0) return 0.0;
    final used = quota.totalPurchased - quota.remainingDeliveries;
    return (used / quota.totalPurchased) * 100;
  }

  /// Calcule le pourcentage de quota restant
  static double getRemainingPercentage(QuotaModel quota) {
    if (quota.totalPurchased == 0) return 0.0;
    return (quota.remainingDeliveries / quota.totalPurchased) * 100;
  }
}
