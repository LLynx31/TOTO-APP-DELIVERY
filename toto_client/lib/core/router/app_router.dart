import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

// Screens (à importer une fois créés)
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/main_scaffold.dart';
import '../../presentation/screens/delivery/history/deliveries_list_screen.dart';
import '../../presentation/screens/delivery/create_delivery_wizard_screen.dart';
import '../../presentation/screens/delivery/tracking_screen.dart';
import '../../presentation/screens/delivery/tracking/qr_display_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/change_password_screen.dart';
import '../../presentation/screens/delivery/payment/payment_screen.dart';
import '../../presentation/screens/delivery/payment/payment_result_screen.dart';
import '../../presentation/screens/rating/rate_delivery_screen.dart';
import '../../presentation/screens/delivery/completion/delivery_success_screen.dart';
import '../../presentation/screens/delivery/recipient/recipient_tracking_screen.dart';

// Provider pour le router
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Configuration du router GoRouter
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,

    // Redirect logic pour l'authentification
    redirect: (context, state) {
      // TODO: Implémenter la logique de redirection basée sur l'auth
      // final isAuthenticated = ref.read(authProvider).isAuthenticated;
      // final isAuthRoute = state.matchedLocation == RoutePaths.login ||
      //     state.matchedLocation == RoutePaths.register;

      // if (!isAuthenticated && !isAuthRoute) {
      //   return RoutePaths.login;
      // }
      // if (isAuthenticated && isAuthRoute) {
      //   return RoutePaths.home;
      // }
      return null;
    },

    routes: [
      // ==================
      // Splash / Root Route
      // ==================
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        redirect: (context, state) => RoutePaths.home,
      ),

      // ==================
      // Auth Routes
      // ==================
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ==================
      // Main Shell Route (avec bottom navigation)
      // ==================
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.deliveries,
            name: RouteNames.deliveries,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeliveriesListScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ==================
      // Delivery Routes
      // ==================
      GoRoute(
        path: RoutePaths.createDelivery,
        name: RouteNames.createDelivery,
        builder: (context, state) => const CreateDeliveryWizardScreen(),
      ),
      GoRoute(
        path: RoutePaths.tracking,
        name: RouteNames.tracking,
        builder: (context, state) {
          final deliveryId = state.pathParameters['id']!;
          return TrackingScreen(deliveryId: deliveryId);
        },
      ),
      GoRoute(
        path: RoutePaths.recipientTracking,
        name: RouteNames.recipientTracking,
        builder: (context, state) {
          final deliveryId = state.pathParameters['id']!;
          return RecipientTrackingScreen(deliveryId: deliveryId);
        },
      ),
      GoRoute(
        path: RoutePaths.qrCode,
        name: RouteNames.qrCode,
        builder: (context, state) {
          final deliveryId = state.pathParameters['id']!;
          final qrType = state.uri.queryParameters['type'] ?? 'pickup';
          return QRDisplayScreen(deliveryId: deliveryId, qrType: qrType);
        },
      ),
      GoRoute(
        path: RoutePaths.rateDelivery,
        name: RouteNames.rateDelivery,
        builder: (context, state) {
          final deliveryId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return RateDeliveryScreen(
            deliveryId: deliveryId,
            delivererName: extra?['delivererName'] ?? 'Livreur',
            delivererPhotoUrl: extra?['delivererPhotoUrl'],
          );
        },
      ),
      GoRoute(
        path: RoutePaths.deliverySuccess,
        name: RouteNames.deliverySuccess,
        builder: (context, state) {
          final deliveryId = state.pathParameters['id']!;
          return DeliverySuccessScreen(deliveryId: deliveryId);
        },
      ),

      // ==================
      // Payment Routes
      // ==================
      GoRoute(
        path: RoutePaths.payment,
        name: RouteNames.payment,
        builder: (context, state) {
          final amount = state.extra as double? ?? 0.0;
          return PaymentScreen(amount: amount);
        },
      ),
      GoRoute(
        path: RoutePaths.paymentResult,
        name: RouteNames.paymentResult,
        builder: (context, state) {
          final result = state.extra as Map<String, dynamic>?;
          return PaymentResultScreen(result: result ?? {});
        },
      ),

      // ==================
      // Profile Routes
      // ==================
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        name: RouteNames.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extension pour la navigation simplifiée
extension GoRouterExtension on BuildContext {
  void goToLogin() => go(RoutePaths.login);
  void goToRegister() => go(RoutePaths.register);
  void goToHome() => go(RoutePaths.home);
  void goToDeliveries() => go(RoutePaths.deliveries);
  void goToProfile() => go(RoutePaths.profile);

  void goToCreateDelivery() => push(RoutePaths.createDelivery);
  void goToTracking(String deliveryId) => push('/delivery/$deliveryId/tracking');
  void goToQRCode(String deliveryId, {String type = 'pickup'}) =>
      push('/delivery/$deliveryId/qr?type=$type');

  void goToPayment(double amount) => push(RoutePaths.payment, extra: amount);
  void goToPaymentResult(Map<String, dynamic> result) =>
      go(RoutePaths.paymentResult, extra: result);

  void goToEditProfile() => push(RoutePaths.editProfile);
  void goToChangePassword() => push(RoutePaths.changePassword);
}
