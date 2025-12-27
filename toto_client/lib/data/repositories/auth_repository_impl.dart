import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth/login_request_dto.dart';
import '../models/auth/register_request_dto.dart';

/// Implémentation du repository d'authentification
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;
  final DioClient dioClient;

  AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.dioClient,
  });

  @override
  Future<Result<User>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final request = LoginRequestDto(
        phoneNumber: phoneNumber,
        password: password,
      );

      final response = await remoteDatasource.login(request);

      // Sauvegarder les tokens et l'utilisateur localement
      await localDatasource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await localDatasource.saveUser(response.user);

      // Sauvegarder aussi dans le DioClient
      await dioClient.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Mapper le DTO vers l'entité
      return Success(_mapUserDtoToEntity(response.user));
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Une erreur est survenue lors de la connexion');
    }
  }

  @override
  Future<Result<User>> register({
    required String phoneNumber,
    required String fullName,
    required String password,
    String? email,
  }) async {
    try {
      final request = RegisterRequestDto(
        phoneNumber: phoneNumber,
        fullName: fullName,
        password: password,
        email: email,
      );

      final response = await remoteDatasource.register(request);

      // Sauvegarder les tokens et l'utilisateur localement
      await localDatasource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await localDatasource.saveUser(response.user);

      // Sauvegarder aussi dans le DioClient
      await dioClient.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return Success(_mapUserDtoToEntity(response.user));
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Une erreur est survenue lors de l\'inscription');
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await localDatasource.getRefreshToken();
      if (refreshToken != null) {
        await remoteDatasource.logout(refreshToken);
      }

      await localDatasource.clearAll();
      await dioClient.clearTokens();

      return const Success(null);
    } catch (e) {
      // Même si la requête échoue, on nettoie localement
      await localDatasource.clearAll();
      await dioClient.clearTokens();
      return const Success(null);
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final userDto = await localDatasource.getUser();
      if (userDto == null) {
        return const Failure('Utilisateur non trouvé');
      }

      return Success(_mapUserDtoToEntity(userDto));
    } catch (e) {
      return const Failure('Erreur lors de la récupération de l\'utilisateur');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await localDatasource.hasValidTokens();
  }

  @override
  Future<Result<User>> updateProfile({
    required String fullName,
    String? email,
  }) async {
    try {
      final data = {
        'full_name': fullName,
        if (email != null) 'email': email,
      };

      final response = await remoteDatasource.updateProfile(data);

      // Mettre à jour l'utilisateur en local
      final userDto = response['user'];
      await localDatasource.saveUser(userDto);

      return Success(_mapUserDtoToEntity(userDto));
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Une erreur est survenue lors de la mise à jour du profil');
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final data = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };

      await remoteDatasource.changePassword(data);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Une erreur est survenue lors du changement de mot de passe');
    }
  }

  // Mapper DTO vers Entity
  User _mapUserDtoToEntity(dynamic userDto) {
    return User(
      id: userDto.id,
      phoneNumber: userDto.phoneNumber,
      fullName: userDto.fullName,
      email: userDto.email,
      photoUrl: userDto.photoUrl,
      isVerified: userDto.isVerified,
      isActive: userDto.isActive,
      createdAt: userDto.createdAt,
    );
  }
}

/// Type Result pour gérer les succès et échecs
sealed class Result<T> {
  const Result();

  /// Permet de traiter les deux cas (succès et échec) avec des fonctions
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(String error) onFailure,
  ) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final message) => onFailure(message),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}
