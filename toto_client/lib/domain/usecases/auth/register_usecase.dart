import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour l'inscription
class RegisterUsecase {
  final AuthRepository repository;

  RegisterUsecase(this.repository);

  Future<Result<User>> call({
    required String phoneNumber,
    required String fullName,
    required String password,
    String? email,
  }) async {
    // Validation
    if (phoneNumber.isEmpty || fullName.isEmpty || password.isEmpty) {
      return const Failure('Veuillez remplir tous les champs obligatoires');
    }

    if (password.length < 6) {
      return const Failure('Le mot de passe doit contenir au moins 6 caractères');
    }

    // Appel au repository
    return await repository.register(
      phoneNumber: phoneNumber,
      fullName: fullName,
      password: password,
      email: email,
    );
  }
}
