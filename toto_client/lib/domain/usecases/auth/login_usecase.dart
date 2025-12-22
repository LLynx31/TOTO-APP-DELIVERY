import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour la connexion
class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<Result<User>> call({
    required String phoneNumber,
    required String password,
  }) async {
    // Validation
    if (phoneNumber.isEmpty || password.isEmpty) {
      return const Failure('Veuillez remplir tous les champs');
    }

    // Appel au repository
    return await repository.login(
      phoneNumber: phoneNumber,
      password: password,
    );
  }
}
