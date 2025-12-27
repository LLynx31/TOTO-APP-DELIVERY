import 'env_config.dart';

/// Configuration de l'API backend
class ApiConfig {
  ApiConfig._();

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Auth Endpoints
  static const String clientRegister = '/auth/client/register';
  static const String clientLogin = '/auth/client/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String updateProfile = '/auth/client/profile';
  static const String changePassword = '/auth/client/password';

  // Delivery Endpoints
  static const String deliveries = '/deliveries';
  static const String availableDeliveries = '/deliveries/available';
  static String deliveryById(String id) => '/deliveries/$id';
  static String acceptDelivery(String id) => '/deliveries/$id/accept';
  static String cancelDelivery(String id) => '/deliveries/$id/cancel';
  static String verifyQR(String id) => '/deliveries/$id/verify-qr';

  // Quota Endpoints
  static const String quotaPackages = '/quotas/packages';
  static const String purchaseQuota = '/quotas/purchase';
  static const String myQuotas = '/quotas/my-quotas';
  static const String activeQuota = '/quotas/active';
  static String quotaHistory(String id) => '/quotas/$id/history';

  // Rating Endpoints
  static const String ratings = '/ratings';
  static String rateDelivery(String deliveryId) => '/deliveries/$deliveryId/rate';
  static String getDeliveryRating(String deliveryId) => '/deliveries/$deliveryId/rating';
  static String checkHasRated(String deliveryId) => '/deliveries/$deliveryId/has-rated';

  // WebSocket - Utilise EnvConfig pour l'URL dynamique
  static String get socketUrl => EnvConfig.socketUrl;
  static const String trackingNamespace = '/tracking';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
}
