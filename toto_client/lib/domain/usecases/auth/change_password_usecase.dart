import '../../repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour changer le mot de passe de l'utilisateur
class ChangePasswordUsecase {
  final AuthRepository repository;

  ChangePasswordUsecase(this.repository);

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
