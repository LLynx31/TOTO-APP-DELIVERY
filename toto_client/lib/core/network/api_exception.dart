/// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isNetworkError => statusCode == null;
}

/// Exception pour les erreurs de réseau
class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Erreur de connexion. Vérifiez votre connexion internet.',
          statusCode: null,
        );
}

/// Exception pour les erreurs de validation
class ValidationException extends ApiException {
  ValidationException({
    required String message,
    dynamic errors,
  }) : super(
          message: message,
          statusCode: 422,
          errors: errors,
        );
}

/// Exception pour les erreurs d'authentification
class AuthException extends ApiException {
  AuthException({String? message})
      : super(
          message: message ?? 'Session expirée. Veuillez vous reconnecter.',
          statusCode: 401,
        );
}
