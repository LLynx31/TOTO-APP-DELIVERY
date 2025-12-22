import '../../repositories/auth_repository.dart';

/// Use case pour vérifier si l'utilisateur est authentifié
class CheckAuthUsecase {
  final AuthRepository repository;

  CheckAuthUsecase(this.repository);

  Future<bool> call() async {
    return await repository.isAuthenticated();
  }
}
