import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth/check_auth_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/di/injection.dart' as di;

/// État d'authentification
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Notifier pour gérer l'état d'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUsecase loginUsecase;
  final RegisterUsecase registerUsecase;
  final LogoutUsecase logoutUsecase;
  final GetCurrentUserUsecase getCurrentUserUsecase;
  final CheckAuthUsecase checkAuthUsecase;

  AuthNotifier({
    required this.loginUsecase,
    required this.registerUsecase,
    required this.logoutUsecase,
    required this.getCurrentUserUsecase,
    required this.checkAuthUsecase,
  }) : super(const AuthInitial());

  /// Vérifier l'authentification au démarrage
  Future<void> checkAuth() async {
    state = const AuthLoading();

    try {
      final isAuthenticated = await checkAuthUsecase();

      if (isAuthenticated) {
        final result = await getCurrentUserUsecase();
        result.fold(
          (user) => state = AuthAuthenticated(user),
          (_) => state = const AuthUnauthenticated(),
        );
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Connexion
  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await loginUsecase(
      phoneNumber: phoneNumber,
      password: password,
    );

    result.fold(
      (user) => state = AuthAuthenticated(user),
      (error) => state = AuthError(error),
    );
  }

  /// Inscription
  Future<void> register({
    required String phoneNumber,
    required String fullName,
    required String password,
    String? email,
  }) async {
    state = const AuthLoading();

    final result = await registerUsecase(
      phoneNumber: phoneNumber,
      fullName: fullName,
      password: password,
      email: email,
    );

    result.fold(
      (user) => state = AuthAuthenticated(user),
      (error) => state = AuthError(error),
    );
  }

  /// Déconnexion
  Future<void> logout() async {
    await logoutUsecase();
    state = const AuthUnauthenticated();
  }

  /// Mettre à jour l'utilisateur (après modification du profil)
  void updateUser(User user) {
    state = AuthAuthenticated(user);
  }
}

/// Provider pour l'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUsecase: ref.watch(di.loginUsecaseProvider),
    registerUsecase: ref.watch(di.registerUsecaseProvider),
    logoutUsecase: ref.watch(di.logoutUsecaseProvider),
    getCurrentUserUsecase: ref.watch(di.getCurrentUserUsecaseProvider),
    checkAuthUsecase: ref.watch(di.checkAuthUsecaseProvider),
  );
});

/// Extension pour faciliter l'utilisation du Result
extension ResultExtension<T> on Result<T> {
  void fold(Function(T) onSuccess, Function(String) onFailure) {
    if (this is Success<T>) {
      onSuccess((this as Success<T>).data);
    } else if (this is Failure<T>) {
      onFailure((this as Failure<T>).message);
    }
  }
}
