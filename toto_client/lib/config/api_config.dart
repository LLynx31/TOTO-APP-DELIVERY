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

  // API Endpoints
  static const String authClientRegister = '/auth/client/register';
  static const String authClientLogin = '/auth/client/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Deliveries
  static const String deliveries = '/deliveries';
  static String deliveryById(String id) => '/deliveries/$id';
  static String deliveryCancel(String id) => '/deliveries/$id/cancel';
  static String deliveryVerifyQR(String id) => '/deliveries/$id/verify-qr';

  // Quotas
  static const String quotasPackages = '/quotas/packages';
  static const String quotasPurchase = '/quotas/purchase';
  static const String quotasMyQuotas = '/quotas/my-quotas';
  static const String quotasActive = '/quotas/active';
  static String quotasHistory(String id) => '/quotas/$id/history';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
