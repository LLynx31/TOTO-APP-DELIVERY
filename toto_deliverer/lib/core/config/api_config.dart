import 'env_config.dart';

class ApiConfig {
  // Base URLs (auto-détection selon la plateforme)
  static String get baseUrl => EnvConfig.baseUrl;
  static String get socketUrl => EnvConfig.socketUrl;

  // API Endpoints - Auth
  static const String authDelivererRegister = '/auth/deliverer/register';
  static const String authDelivererLogin = '/auth/deliverer/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Deliverers - Profile (via JWT, pas d'ID)
  static const String delivererMe = '/deliverers/me';
  static const String delivererMeStats = '/deliverers/me/stats';
  static const String delivererMeStatsDaily = '/deliverers/me/stats/daily';
  static const String delivererMeAvailability = '/deliverers/me/availability';
  static const String delivererMeEarnings = '/deliverers/me/earnings';

  // Deliverers - Par ID (pour admin)
  static String delivererById(String id) => '/deliverers/$id';
  static String delivererStatus(String id) => '/deliverers/$id/status';
  static String delivererDocuments(String id) => '/deliverers/$id/documents';
  static String delivererStats(String id) => '/deliverers/$id/stats';
  static String delivererVehicle(String id) => '/deliverers/$id/vehicle';

  // Deliveries
  static const String deliveries = '/deliveries';
  // Endpoint dédié pour les livraisons disponibles (toutes les pending sans livreur assigné)
  static const String deliveriesAvailable = '/deliveries/available';
  // Livraisons du livreur connecté (filtrées par status si besoin)
  static const String deliveriesActive = '/deliveries'; // Filtrage côté client
  static const String deliveriesCompleted = '/deliveries'; // + ?status=delivered

  static String deliveryById(String id) => '/deliveries/$id';
  static String deliveryAccept(String id) => '/deliveries/$id/accept';
  static String deliveryCancel(String id) => '/deliveries/$id/cancel';
  static String deliveryProblem(String id) => '/deliveries/$id/problem';

  // Backend unifié: verify-qr remplace confirm-pickup et confirm-delivery
  static String deliveryVerifyQR(String id) => '/deliveries/$id/verify-qr';
  // Pour les changements de status via PATCH
  static String deliveryUpdate(String id) => '/deliveries/$id';

  // Rating endpoints (bidirectional rating system)
  static String rateDelivery(String id) => '/deliveries/$id/rate';
  static String getDeliveryRating(String id) => '/deliveries/$id/rating';
  static String checkHasRated(String id) => '/deliveries/$id/has-rated';
  static String deliveryQRCodes(String id) => '/deliveries/$id/qr-codes';
  static String deliveryTracking(String id) => '/deliveries/$id/tracking';

  // Quotas (Backend utilise JWT pour identifier l'utilisateur)
  static const String quotasActive = '/quotas/active'; // Quota actif (via JWT)
  static const String quotasMyQuotas = '/quotas/my-quotas'; // Tous les quotas
  static const String quotasPackages = '/quotas/packages'; // Packs disponibles
  static const String quotasPurchase = '/quotas/purchase'; // Acheter quota
  static const String quotasTransactions = '/quotas/transactions'; // Historique achats
  static String quotasHistory(String quotaId) => '/quotas/$quotaId/history';
  static String quotasTransactionStatus(String id) => '/quotas/transactions/$id/status';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Statistics
  static String statisticsDeliverer(String id) => '/statistics/deliverer/$id';

  // Storage
  static const String storageUpload = '/storage/upload';
  static String storageFile(String category, String filename) => '/storage/$category/$filename';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Token expiry (en secondes)
  static const int accessTokenExpiry = 3600; // 1 heure
  static const int refreshTokenExpiry = 604800; // 7 jours

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'deliverer_data';
}
