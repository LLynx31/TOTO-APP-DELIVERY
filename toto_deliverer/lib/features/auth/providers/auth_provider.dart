import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final Map<String, dynamic>? deliverer;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.deliverer,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Map<String, dynamic>? deliverer,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      deliverer: deliverer ?? this.deliverer,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState());

  // Initialiser
  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.init();
      state = state.copyWith(
        isAuthenticated: _authService.isAuthenticated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Inscription
  Future<void> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    String? email,
    required String vehicleType,
    required String vehicleRegistration,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.registerDeliverer(
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
        email: email,
        vehicleType: vehicleType,
        vehicleRegistration: vehicleRegistration,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        deliverer: response.deliverer,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Connexion
  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.loginDeliverer(
        phoneNumber: phoneNumber,
        password: password,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        deliverer: response.deliverer,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
