import '../config/api_config.dart';
import '../../shared/models/deliverer_model.dart';
import 'api_client.dart';

class DelivererService {
  final _apiClient = ApiClient();

  // Initialiser l'API client
  Future<void> init() async {
    await _apiClient.init();
  }

  /// Récupérer le profil du livreur connecté
  Future<DelivererModel> getProfile() async {
    print('👤 DelivererService.getProfile() appelé');
    print('🌐 URL: ${ApiConfig.baseUrl}${ApiConfig.delivererMe}');

    final response = await _apiClient.get(ApiConfig.delivererMe);

    print('✅ Réponse profil reçue: ${response.statusCode}');

    return DelivererModel.fromJson(response.data);
  }

  /// Mettre à jour le profil du livreur
  Future<DelivererModel> updateProfile({
    String? fullName,
    String? email,
    String? photoUrl,
    String? vehicleType,
    String? licensePlate,
  }) async {
    print('📝 DelivererService.updateProfile() appelé');

    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (vehicleType != null) data['vehicle_type'] = vehicleType;
    if (licensePlate != null) data['license_plate'] = licensePlate;

    final response = await _apiClient.patch(
      ApiConfig.delivererMe,
      data: data,
    );

    print('✅ Profil mis à jour: ${response.statusCode}');

    return DelivererModel.fromJson(response.data);
  }

  /// Mettre à jour le statut de disponibilité (en ligne / hors ligne)
  Future<bool> updateAvailability(bool isAvailable) async {
    print('🔄 DelivererService.updateAvailability($isAvailable) appelé');

    final response = await _apiClient.patch(
      ApiConfig.delivererMeAvailability,
      data: {'is_available': isAvailable},
    );

    print('✅ Disponibilité mise à jour: ${response.statusCode}');
    print('📦 Réponse: ${response.data}');

    // L'ApiClient transforme snake_case → camelCase, donc vérifier les deux
    return (response.data['isAvailable'] ?? response.data['is_available']) as bool;
  }

  /// Récupérer les statistiques du livreur
  Future<DelivererStats> getStats() async {
    print('📊 DelivererService.getStats() appelé');

    final response = await _apiClient.get(ApiConfig.delivererMeStats);

    print('✅ Stats reçues: ${response.statusCode}');

    return DelivererStats.fromJson(response.data);
  }

  /// Récupérer les statistiques journalières du livreur
  Future<DailyStats> getDailyStats() async {
    print('📊 DelivererService.getDailyStats() appelé');

    final response = await _apiClient.get(ApiConfig.delivererMeStatsDaily);

    print('✅ Stats journalières reçues: ${response.statusCode}');

    return DailyStats.fromJson(response.data);
  }

  /// Récupérer les gains du livreur
  Future<EarningsData> getEarnings({String period = 'today'}) async {
    print('💰 DelivererService.getEarnings($period) appelé');

    final response = await _apiClient.get(
      '${ApiConfig.delivererMeEarnings}?period=$period',
    );

    print('✅ Gains reçus: ${response.statusCode}');

    return EarningsData.fromJson(response.data);
  }
}

/// Statistiques du livreur
class DelivererStats {
  final int totalDeliveries;
  final double rating;
  final bool isVerified;
  final String kycStatus;

  DelivererStats({
    required this.totalDeliveries,
    required this.rating,
    required this.isVerified,
    required this.kycStatus,
  });

  factory DelivererStats.fromJson(Map<String, dynamic> json) {
    // ApiClient transforme snake_case → camelCase, supporter les deux
    final ratingValue = json['rating'];
    return DelivererStats(
      totalDeliveries: json['totalDeliveries'] ?? json['total_deliveries'] ?? 0,
      rating: (ratingValue is String)
          ? double.tryParse(ratingValue) ?? 0.0
          : (ratingValue as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      kycStatus: json['kycStatus'] ?? json['kyc_status'] ?? 'pending',
    );
  }
}

/// Statistiques journalières
class DailyStats {
  final int deliveriesToday;
  final double earningsToday;
  final int completedToday;
  final int inProgress;

  DailyStats({
    required this.deliveriesToday,
    required this.earningsToday,
    required this.completedToday,
    required this.inProgress,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    // ApiClient transforme snake_case → camelCase, supporter les deux
    return DailyStats(
      deliveriesToday: json['deliveriesToday'] ?? json['deliveries_today'] ?? 0,
      earningsToday: _parseDouble(json['earningsToday'] ?? json['earnings_today']),
      completedToday: json['completedToday'] ?? json['completed_today'] ?? 0,
      inProgress: json['inProgress'] ?? json['in_progress'] ?? 0,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }
}

/// Données de gains
class EarningsData {
  final double total;
  final String period;
  final int deliveriesCount;
  final List<EarningDetail> details;

  EarningsData({
    required this.total,
    required this.period,
    required this.deliveriesCount,
    required this.details,
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      total: (json['total'] is String)
          ? double.tryParse(json['total']) ?? 0.0
          : (json['total'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] ?? 'today',
      deliveriesCount: json['deliveries_count'] ?? 0,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => EarningDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Détail d'un gain
class EarningDetail {
  final String id;
  final double amount;
  final DateTime deliveredAt;
  final String pickupAddress;
  final String deliveryAddress;

  EarningDetail({
    required this.id,
    required this.amount,
    required this.deliveredAt,
    required this.pickupAddress,
    required this.deliveryAddress,
  });

  factory EarningDetail.fromJson(Map<String, dynamic> json) {
    return EarningDetail(
      id: json['id'] ?? '',
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] as num?)?.toDouble() ?? 0.0,
      deliveredAt: DateTime.tryParse(json['delivered_at'] ?? '') ?? DateTime.now(),
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
    );
  }
}
