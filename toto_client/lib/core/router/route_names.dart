/// Noms des routes de l'application
class RouteNames {
  RouteNames._();

  // Auth
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';

  // Main navigation
  static const String home = 'home';
  static const String deliveries = 'deliveries';
  static const String quota = 'quota';
  static const String profile = 'profile';

  // Delivery
  static const String createDelivery = 'create-delivery';
  static const String deliveryDetails = 'delivery-details';
  static const String tracking = 'tracking';
  static const String recipientTracking = 'recipient-tracking';
  static const String qrCode = 'qr-code';
  static const String rateDelivery = 'rate-delivery';
  static const String deliverySuccess = 'delivery-success';

  // Quota
  static const String purchaseQuota = 'purchase-quota';
  static const String quotaHistory = 'quota-history';

  // Payment
  static const String payment = 'payment';
  static const String paymentResult = 'payment-result';

  // Profile
  static const String editProfile = 'edit-profile';
  static const String changePassword = 'change-password';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
}

/// Chemins des routes
class RoutePaths {
  RoutePaths._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main navigation (shell route children)
  static const String home = '/home';
  static const String deliveries = '/deliveries';
  static const String quota = '/quota';
  static const String profile = '/profile';

  // Delivery
  static const String createDelivery = '/delivery/create';
  static const String deliveryDetails = '/delivery/:id';
  static const String tracking = '/delivery/:id/tracking';
  static const String recipientTracking = '/recipient/:id/tracking';
  static const String qrCode = '/delivery/:id/qr';
  static const String rateDelivery = '/delivery/:id/rate';
  static const String deliverySuccess = '/delivery/:id/success';

  // Quota
  static const String purchaseQuota = '/quota/purchase';
  static const String quotaHistory = '/quota/:id/history';

  // Payment
  static const String payment = '/payment';
  static const String paymentResult = '/payment/result';

  // Profile
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
}
