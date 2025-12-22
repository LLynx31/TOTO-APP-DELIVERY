import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour mettre à jour le profil de l'utilisateur
class UpdateProfileUsecase {
  final AuthRepository repository;

  UpdateProfileUsecase(this.repository);

  Future<Result<User>> call({
    required String fullName,
    String? email,
  }) async {
    return await repository.updateProfile(
      fullName: fullName,
      email: email,
    );
  }
}
