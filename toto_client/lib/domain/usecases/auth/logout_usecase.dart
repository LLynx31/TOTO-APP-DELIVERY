import '../../repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour la déconnexion
class LogoutUsecase {
  final AuthRepository repository;

  LogoutUsecase(this.repository);

  Future<Result<void>> call() async {
    return await repository.logout();
  }
}
