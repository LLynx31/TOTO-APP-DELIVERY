import '../config/api_config.dart';
import 'api_client.dart';

class QuotaService {
  final _apiClient = ApiClient();

  // Récupérer le quota actif du livreur
  Future<Map<String, dynamic>?> getActiveQuota(String delivererId) async {
    final response = await _apiClient.get(
      ApiConfig.quotasDeliverer(delivererId),
    );
    return response.data as Map<String, dynamic>?;
  }

  // Acheter un pack de quotas
  Future<Map<String, dynamic>> purchaseQuota({
    required String delivererId,
    required String packageId,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.quotasPurchase,
      data: {
        'deliverer_id': delivererId,
        'package_id': packageId,
        'payment_method': paymentMethod,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Vérifier le statut d'une transaction
  Future<Map<String, dynamic>> getTransactionStatus(String transactionId) async {
    final response = await _apiClient.get(
      ApiConfig.quotasTransactionStatus(transactionId),
    );
    return response.data as Map<String, dynamic>;
  }

  // Récupérer l'historique des quotas
  Future<List<dynamic>> getQuotaHistory(String delivererId) async {
    final response = await _apiClient.get(
      ApiConfig.quotasHistory(delivererId),
    );
    return response.data as List<dynamic>;
  }
}
