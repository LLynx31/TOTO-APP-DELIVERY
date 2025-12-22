/// Configuration de l'API backend
class ApiConfig {
  ApiConfig._();

  // Base URL
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // iOS simulator
  // static const String baseUrl = 'https://api.toto.ci'; // Production

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Token expiry (en secondes)
  static const int accessTokenExpiry = 3600; // 1 heure
  static const int refreshTokenExpiry = 604800; // 7 jours

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

  // WebSocket
  static const String socketUrl = 'http://10.0.2.2:3000';
  // static const String socketUrl = 'http://localhost:3000'; // iOS
  // static const String socketUrl = 'https://api.toto.ci'; // Production
  static const String trackingNamespace = '/tracking';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
}
