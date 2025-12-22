import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../models/auth/auth_response_dto.dart';
import '../../models/auth/login_request_dto.dart';
import '../../models/auth/register_request_dto.dart';

/// Interface pour la source de données distante d'authentification
abstract class AuthRemoteDatasource {
  Future<AuthResponseDto> login(LoginRequestDto request);
  Future<AuthResponseDto> register(RegisterRequestDto request);
  Future<void> logout(String refreshToken);
  Future<dynamic> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword(Map<String, dynamic> data);
}

/// Implémentation de la source de données distante d'authentification
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final DioClient dioClient;

  AuthRemoteDatasourceImpl(this.dioClient);

  @override
  Future<AuthResponseDto> login(LoginRequestDto request) async {
    final response = await dioClient.post(
      ApiConfig.clientLogin,
      data: request.toJson(),
    );

    return AuthResponseDto.fromJson(response.data);
  }

  @override
  Future<AuthResponseDto> register(RegisterRequestDto request) async {
    final response = await dioClient.post(
      ApiConfig.clientRegister,
      data: request.toJson(),
    );

    return AuthResponseDto.fromJson(response.data);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await dioClient.post(
      ApiConfig.logout,
      data: {'refresh_token': refreshToken},
    );
  }

  @override
  Future<dynamic> updateProfile(Map<String, dynamic> data) async {
    final response = await dioClient.put(
      ApiConfig.updateProfile,
      data: data,
    );
    return response.data;
  }

  @override
  Future<void> changePassword(Map<String, dynamic> data) async {
    await dioClient.put(
      ApiConfig.changePassword,
      data: data,
    );
  }
}
