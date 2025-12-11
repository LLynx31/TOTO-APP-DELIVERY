class ApiConfig {
  // Base URLs
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator localhost
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // API Endpoints - Auth
  static const String authDelivererRegister = '/auth/deliverer/register';
  static const String authDelivererLogin = '/auth/deliverer/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Deliverers
  static String delivererById(String id) => '/deliverers/$id';
  static String delivererStatus(String id) => '/deliverers/$id/status';
  static String delivererDocuments(String id) => '/deliverers/$id/documents';
  static String delivererStats(String id) => '/deliverers/$id/stats';
  static String delivererVehicle(String id) => '/deliverers/$id/vehicle';

  // Deliveries
  static const String deliveries = '/deliveries';
  static const String deliveriesAvailable = '/deliveries/available';
  static const String deliveriesActive = '/deliveries/active';
  static const String deliveriesCompleted = '/deliveries/completed';
  static String deliveryById(String id) => '/deliveries/$id';
  static String deliveryAccept(String id) => '/deliveries/$id/accept';
  static String deliveryStartPickup(String id) => '/deliveries/$id/start-pickup';
  static String deliveryConfirmPickup(String id) => '/deliveries/$id/confirm-pickup';
  static String deliveryStartDelivery(String id) => '/deliveries/$id/start-delivery';
  static String deliveryConfirmDelivery(String id) => '/deliveries/$id/confirm-delivery';
  static String deliveryCancel(String id) => '/deliveries/$id/cancel';
  static String deliveryRating(String id) => '/deliveries/$id/rating-customer';
  static String deliveryProblem(String id) => '/deliveries/$id/problem';
  static String deliveryQRCodes(String id) => '/deliveries/$id/qr-codes';
  static String deliveryTracking(String id) => '/deliveries/$id/tracking';

  // Quotas
  static String quotasDeliverer(String delivererId) => '/quotas/$delivererId';
  static const String quotasPurchase = '/quotas/purchase';
  static String quotasTransactionStatus(String id) => '/quotas/transactions/$id/status';
  static String quotasHistory(String delivererId) => '/quotas/$delivererId/history';

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
}
