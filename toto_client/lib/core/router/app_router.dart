import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../presentation/providers/auth_provider.dart';

// Screens
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
import '../../presentation/screens/rating/rate_delivery_screen.dart';
import '../../presentation/screens/delivery/completion/delivery_success_screen.dart';
import '../../presentation/screens/delivery/recipient/recipient_tracking_screen.dart';

/// Classe pour écouter les changements d'état d'authentification
class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }

  final Ref _ref;

  bool get isAuthenticated {
    final state = _ref.read(authProvider);
    return state is AuthAuthenticated;
  }

  bool get isLoading {
    final state = _ref.read(authProvider);
    return state is AuthLoading || state is AuthInitial;
  }
}

/// Provider pour le Listenable d'authentification
final authListenableProvider = Provider<AuthNotifierListenable>((ref) {
  return AuthNotifierListenable(ref);
});

/// Provider pour le router
final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(authListenableProvider);

  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: RoutePaths.splash, // Commencer par splash pour vérifier l'auth
    debugLogDiagnostics: true,
    refreshListenable: authListenable,

    // Redirect logic pour l'authentification
    redirect: (context, state) {
      final isAuthenticated = authListenable.isAuthenticated;
      final isLoading = authListenable.isLoading;

      final isAuthRoute = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register;

      final isSplashRoute = state.matchedLocation == RoutePaths.splash;

      final isRecipientRoute = state.matchedLocation.startsWith('/recipient/');

      // Pendant le chargement initial (splash), laisser afficher le splash
      if (isLoading && isSplashRoute) {
        return null;
      }

      // Si sur splash et plus en chargement, rediriger selon l'auth
      if (isSplashRoute && !isLoading) {
        return isAuthenticated ? RoutePaths.home : RoutePaths.login;
      }

      // Si non authentifié et pas sur une route auth, rediriger vers login
      // Exception: les routes recipient sont accessibles sans auth
      if (!isAuthenticated && !isAuthRoute && !isRecipientRoute && !isLoading) {
        return RoutePaths.login;
      }

      // Si authentifié et sur une route auth, rediriger vers home
      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      return null;
    },

    routes: [
      // ==================
      // Splash / Root Route - Vérifie l'auth au démarrage
      // ==================
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const _SplashScreen(),
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
        navigatorKey: GlobalKey<NavigatorState>(),
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
});

/// Écran de splash temporaire pendant la vérification de l'auth
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifier l'authentification au démarrage
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_rounded,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'TOTO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
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

  void goToEditProfile() => push(RoutePaths.editProfile);
  void goToChangePassword() => push(RoutePaths.changePassword);
}
