import '../config/api_config.dart';
import '../models/quota_model.dart';
import 'api_client.dart';

class QuotaService {
  final _apiClient = ApiClient();

  // Récupérer tous les forfaits disponibles
  Future<List<QuotaPackageModel>> getAvailablePackages() async {
    final response = await _apiClient.get(
      ApiConfig.quotasPackages,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => QuotaPackageModel.fromJson(json)).toList();
  }

  // Acheter un forfait
  Future<ClientQuotaModel> purchasePackage(String packageId) async {
    final response = await _apiClient.post(
      ApiConfig.quotasPurchase,
      data: {'package_id': packageId},
    );

    return ClientQuotaModel.fromJson(response.data);
  }

  // Récupérer tous les quotas du client
  Future<List<ClientQuotaModel>> getMyQuotas() async {
    final response = await _apiClient.get(
      ApiConfig.quotasMyQuotas,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => ClientQuotaModel.fromJson(json)).toList();
  }

  // Récupérer le quota actif du client
  Future<ClientQuotaModel?> getActiveQuota() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.quotasActive,
      );

      if (response.data == null) {
        return null;
      }

      return ClientQuotaModel.fromJson(response.data);
    } catch (e) {
      // Si pas de quota actif, retourner null
      return null;
    }
  }

  // Récupérer l'historique d'utilisation d'un quota
  Future<List<QuotaUsageHistoryModel>> getQuotaHistory(String quotaId) async {
    final response = await _apiClient.get(
      ApiConfig.quotasHistory(quotaId),
    );

    final List<dynamic> data = response.data;
    return data
        .map((json) => QuotaUsageHistoryModel.fromJson(json))
        .toList();
  }
}
