import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> deliverer;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.deliverer,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (from backend) and snake_case formats
    return AuthResponse(
      accessToken: json['accessToken'] ?? json['access_token'],
      refreshToken: json['refreshToken'] ?? json['refresh_token'],
      deliverer: json['deliverer'] ?? {},
    );
  }
}

class AuthService {
  final _apiClient = ApiClient();

  // Initialiser l'API client
  Future<void> init() async {
    await _apiClient.init();
  }

  // Inscription livreur avec documents KYC
  Future<AuthResponse> registerDeliverer({
    required String phoneNumber,
    required String password,
    required String fullName,
    String? email,
    required String vehicleType,
    required String vehicleRegistration,
    File? drivingLicense,
    File? idCard,
    File? vehiclePhoto,
  }) async {
    print('📝 AuthService.registerDeliverer() appelé');
    print('📞 Phone: $phoneNumber');
    print('📄 Documents: license=${drivingLicense != null}, id=${idCard != null}, vehicle=${vehiclePhoto != null}');
    print('🌐 URL: ${ApiConfig.baseUrl}${ApiConfig.authDelivererRegister}');

    // Créer le FormData avec les données et les fichiers
    final formData = FormData.fromMap({
      'phone_number': phoneNumber,
      'password': password,
      'full_name': fullName,
      if (email != null) 'email': email,
      'vehicle_type': vehicleType,
      'license_plate': vehicleRegistration,
    });

    // Ajouter les fichiers KYC si présents
    if (drivingLicense != null) {
      formData.files.add(MapEntry(
        'driving_license',
        await MultipartFile.fromFile(
          drivingLicense.path,
          filename: 'driving_license_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
      print('📎 Fichier driving_license ajouté');
    }

    if (idCard != null) {
      formData.files.add(MapEntry(
        'id_card',
        await MultipartFile.fromFile(
          idCard.path,
          filename: 'id_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
      print('📎 Fichier id_card ajouté');
    }

    if (vehiclePhoto != null) {
      formData.files.add(MapEntry(
        'vehicle_photo',
        await MultipartFile.fromFile(
          vehiclePhoto.path,
          filename: 'vehicle_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
      print('📎 Fichier vehicle_photo ajouté');
    }

    print('📤 Envoi de la requête multipart...');
    final response = await _apiClient.postMultipart(
      ApiConfig.authDelivererRegister,
      formData: formData,
    );

    print('✅ Réponse inscription: ${response.statusCode}');
    print('📦 Réponse data: ${response.data}');

    final authResponse = AuthResponse.fromJson(response.data);
    await _apiClient.saveTokens(
      authResponse.accessToken,
      authResponse.refreshToken,
    );

    print('💾 Tokens sauvegardés');
    return authResponse;
  }

  // Connexion livreur
  Future<AuthResponse> loginDeliverer({
    required String phoneNumber,
    required String password,
  }) async {
    print('🔐 AuthService.loginDeliverer() appelé');
    print('📞 Phone: $phoneNumber');
    print('🌐 URL: ${ApiConfig.baseUrl}${ApiConfig.authDelivererLogin}');

    final response = await _apiClient.post(
      ApiConfig.authDelivererLogin,
      data: {
        'phone_number': phoneNumber,
        'password': password,
      },
    );

    print('✅ Réponse reçue du backend: ${response.statusCode}');
    print('📦 Data keys: ${(response.data as Map<String, dynamic>).keys}');

    final authResponse = AuthResponse.fromJson(response.data);
    await _apiClient.saveTokens(
      authResponse.accessToken,
      authResponse.refreshToken,
    );

    print('💾 Tokens sauvegardés avec succès');
    return authResponse;
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      final refreshToken = await _apiClient.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(
          ApiConfig.authLogout,
          data: {'refresh_token': refreshToken},
        );
      }
    } finally {
      await _apiClient.clearTokens();
    }
  }

  // Vérifier si authentifié
  bool get isAuthenticated => _apiClient.isAuthenticated;
}
