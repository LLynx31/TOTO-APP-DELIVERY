import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/api_config.dart';
import '../../models/user/user_dto.dart';

/// Interface pour la source de données locale d'authentification
abstract class AuthLocalDatasource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> saveUser(UserDto user);
  Future<UserDto?> getUser();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAll();
  Future<bool> hasValidTokens();
}

/// Implémentation de la source de données locale d'authentification
class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  final FlutterSecureStorage storage;

  AuthLocalDatasourceImpl(this.storage);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storage.write(key: ApiConfig.accessTokenKey, value: accessToken);
    await storage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> saveUser(UserDto user) async {
    final userJson = jsonEncode(user.toJson());
    await storage.write(key: ApiConfig.userKey, value: userJson);
  }

  @override
  Future<UserDto?> getUser() async {
    final userJson = await storage.read(key: ApiConfig.userKey);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserDto.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return await storage.read(key: ApiConfig.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await storage.read(key: ApiConfig.refreshTokenKey);
  }

  @override
  Future<void> clearAll() async {
    await storage.delete(key: ApiConfig.accessTokenKey);
    await storage.delete(key: ApiConfig.refreshTokenKey);
    await storage.delete(key: ApiConfig.userKey);
  }

  @override
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }
}
