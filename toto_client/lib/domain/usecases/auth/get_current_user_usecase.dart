import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Use case pour récupérer l'utilisateur courant
class GetCurrentUserUsecase {
  final AuthRepository repository;

  GetCurrentUserUsecase(this.repository);

  Future<Result<User>> call() async {
    return await repository.getCurrentUser();
  }
}
