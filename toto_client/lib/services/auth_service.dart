import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    );
  }
}

class AuthService {
  final _apiClient = ApiClient();

  // Inscription client
  Future<AuthResponse> registerClient({
    required String phoneNumber,
    required String password,
    required String fullName,
    String? email,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.authClientRegister,
      data: {
        'phone_number': phoneNumber,
        'password': password,
        'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

    // Sauvegarder les tokens
    await _apiClient.saveTokens(
      authResponse.accessToken,
      authResponse.refreshToken,
    );

    return authResponse;
  }

  // Connexion client
  Future<AuthResponse> loginClient({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.authClientLogin,
      data: {
        'phone_number': phoneNumber,
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

    // Sauvegarder les tokens
    await _apiClient.saveTokens(
      authResponse.accessToken,
      authResponse.refreshToken,
    );

    return authResponse;
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      // Récupérer le refresh token depuis le storage
      final refreshToken = await _apiClient.getRefreshToken();

      if (refreshToken != null) {
        await _apiClient.post(
          ApiConfig.authLogout,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      // Ignorer les erreurs de déconnexion côté serveur
    } finally {
      // Toujours supprimer les tokens localement
      await _apiClient.clearTokens();
    }
  }

  // Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => _apiClient.isAuthenticated;

  // Initialiser le service
  Future<void> init() async {
    await _apiClient.init();
  }
}
