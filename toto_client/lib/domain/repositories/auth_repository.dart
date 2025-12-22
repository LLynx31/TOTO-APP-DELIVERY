import '../entities/user.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Interface du repository d'authentification
abstract class AuthRepository {
  Future<Result<User>> login({
    required String phoneNumber,
    required String password,
  });

  Future<Result<User>> register({
    required String phoneNumber,
    required String fullName,
    required String password,
    String? email,
  });

  Future<Result<void>> logout();

  Future<Result<User>> getCurrentUser();

  Future<bool> isAuthenticated();

  Future<Result<User>> updateProfile({
    required String fullName,
    String? email,
  });

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
