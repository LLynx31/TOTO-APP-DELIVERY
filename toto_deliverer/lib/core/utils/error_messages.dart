/// Utility class to convert exceptions to user-friendly French messages.
///
/// This class maps common error patterns to localized messages that users
/// can understand, avoiding technical jargon.
class ErrorMessages {
  /// Converts an exception or error to a user-friendly French message.
  ///
  /// [error] can be an Exception, Error, or any object with toString().
  static String fromException(dynamic error) {
    final message = error.toString().toLowerCase();

    // Authentication errors
    if (message.contains('invalid credentials') ||
        message.contains('invalid password') ||
        message.contains('wrong password') ||
        message.contains('unauthorized') ||
        message.contains('401')) {
      return 'Numéro de téléphone ou mot de passe incorrect.';
    }

    // User not found
    if (message.contains('user not found') ||
        message.contains('account not found') ||
        message.contains('no user')) {
      return 'Aucun compte trouvé avec ce numéro.';
    }

    // Account already exists
    if (message.contains('already exists') ||
        message.contains('already registered') ||
        message.contains('duplicate') ||
        message.contains('phone number already')) {
      return 'Ce numéro de téléphone est déjà enregistré.';
    }

    // Account not verified/approved
    if (message.contains('not verified') ||
        message.contains('pending verification') ||
        message.contains('account pending')) {
      return 'Votre compte est en cours de vérification.';
    }

    // Account suspended/blocked
    if (message.contains('suspended') ||
        message.contains('blocked') ||
        message.contains('disabled')) {
      return 'Votre compte a été suspendu. Contactez le support.';
    }

    // Network errors
    if (message.contains('socket') ||
        message.contains('connection refused') ||
        message.contains('connection failed') ||
        message.contains('network') ||
        message.contains('no internet') ||
        message.contains('unreachable')) {
      return 'Erreur de connexion. Vérifiez votre réseau.';
    }

    // Timeout errors
    if (message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('took too long')) {
      return 'La requête a expiré. Réessayez.';
    }

    // Server errors
    if (message.contains('500') ||
        message.contains('internal server') ||
        message.contains('server error')) {
      return 'Erreur serveur. Réessayez plus tard.';
    }

    // Service unavailable
    if (message.contains('503') ||
        message.contains('service unavailable') ||
        message.contains('maintenance')) {
      return 'Service temporairement indisponible.';
    }

    // Bad request / Validation errors
    if (message.contains('400') ||
        message.contains('bad request') ||
        message.contains('invalid')) {
      return 'Données invalides. Vérifiez vos informations.';
    }

    // Forbidden
    if (message.contains('403') ||
        message.contains('forbidden') ||
        message.contains('not allowed')) {
      return 'Action non autorisée.';
    }

    // Not found (resource)
    if (message.contains('404') ||
        message.contains('not found')) {
      return 'Ressource introuvable.';
    }

    // Rate limiting
    if (message.contains('429') ||
        message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Trop de tentatives. Patientez quelques minutes.';
    }

    // Token/Session errors
    if (message.contains('token expired') ||
        message.contains('session expired') ||
        message.contains('invalid token')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }

    // Quota errors
    if (message.contains('quota') ||
        message.contains('insufficient balance') ||
        message.contains('no credits')) {
      return 'Quota insuffisant. Rechargez votre compte.';
    }

    // Location/GPS errors
    if (message.contains('location') ||
        message.contains('gps') ||
        message.contains('geolocation')) {
      return 'Erreur de localisation. Activez le GPS.';
    }

    // Permission errors
    if (message.contains('permission') ||
        message.contains('denied')) {
      return 'Permission refusée. Vérifiez les paramètres.';
    }

    // File/Upload errors
    if (message.contains('upload') ||
        message.contains('file too large') ||
        message.contains('file size')) {
      return 'Erreur lors du téléchargement du fichier.';
    }

    // Delivery-specific errors
    if (message.contains('delivery not found') ||
        message.contains('course not found')) {
      return 'Livraison introuvable.';
    }

    if (message.contains('already accepted') ||
        message.contains('already taken')) {
      return 'Cette livraison a déjà été acceptée.';
    }

    if (message.contains('cannot cancel') ||
        message.contains('cannot complete')) {
      return 'Action impossible sur cette livraison.';
    }

    // Default message
    return 'Une erreur est survenue. Réessayez.';
  }

  /// Returns a specific message for login failures
  static String loginError(dynamic error) {
    // Nettoyer le message d'erreur
    final String rawMessage = error.toString();
    final String message = rawMessage.toLowerCase();

    print('🔍 ErrorMessages.loginError - Message brut: "$rawMessage"');
    print('🔍 ErrorMessages.loginError - Message lowercase: "$message"');

    // Erreurs d'authentification - identifiants incorrects
    // Vérifier d'abord les patterns exacts du backend
    if (message.contains('invalid credentials') ||
        message.contains('invalid password') ||
        message.contains('wrong password') ||
        message.contains('unauthorized') ||
        message.contains('401') ||
        message.contains('incorrect') ||
        message.contains('non autorisé') ||
        message.contains('authentication failed') ||
        message.contains('login failed') ||
        message.contains('veuillez vous reconnecter')) {
      print('✅ Détecté comme: Identifiants incorrects');
      return 'Numéro de téléphone ou mot de passe incorrect.';
    }

    // Compte non trouvé
    if (message.contains('user not found') ||
        message.contains('deliverer not found') ||
        message.contains('account not found') ||
        message.contains('no user') ||
        message.contains('no account') ||
        message.contains('aucun compte') ||
        message.contains('introuvable')) {
      print('✅ Détecté comme: Compte non trouvé');
      return 'Aucun compte trouvé avec ce numéro de téléphone.';
    }

    // Compte désactivé
    if (message.contains('deactivated') ||
        message.contains('disabled') ||
        message.contains('suspended') ||
        message.contains('blocked') ||
        message.contains('désactivé') ||
        message.contains('suspendu')) {
      print('✅ Détecté comme: Compte désactivé');
      return 'Votre compte a été désactivé. Contactez le support.';
    }

    // Compte en attente de validation
    if (message.contains('pending') ||
        message.contains('not verified') ||
        message.contains('not approved') ||
        message.contains('en attente')) {
      print('✅ Détecté comme: Compte en attente');
      return 'Votre compte est en attente de validation par un administrateur.';
    }

    print('⚠️ Aucun pattern détecté, utilisation de fromException()');
    return fromException(error);
  }

  /// Returns a specific message for signup failures
  static String signupError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('already exists') ||
        message.contains('duplicate')) {
      return 'Ce numéro de téléphone est déjà enregistré.';
    }

    return fromException(error);
  }

  /// Returns a specific message for delivery operations
  static String deliveryError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('already accepted')) {
      return 'Cette livraison a déjà été acceptée par un autre livreur.';
    }

    if (message.contains('cannot accept')) {
      return 'Vous ne pouvez pas accepter cette livraison.';
    }

    return fromException(error);
  }
}
