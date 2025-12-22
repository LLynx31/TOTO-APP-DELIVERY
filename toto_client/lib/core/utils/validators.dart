/// Validateurs de formulaires
class Validators {
  Validators._();

  /// Valide un numéro de téléphone ivoirien
  /// Format attendu: +225XXXXXXXXXX (10 chiffres après +225)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }

    // Nettoyer le numéro
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Vérifier le format +225 suivi de 10 chiffres
    final phoneRegex = RegExp(r'^\+225[0-9]{10}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Format invalide. Ex: +225 07 12 34 56 78';
    }

    return null;
  }

  /// Valide un mot de passe (minimum 6 caractères)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    return null;
  }

  /// Valide la confirmation du mot de passe
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  /// Valide un email (optionnel)
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email optionnel
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  /// Valide un nom complet
  static String? fullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }

    if (value.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    return null;
  }

  /// Valide un champ requis
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName est requis' : 'Ce champ est requis';
    }
    return null;
  }

  /// Valide une adresse
  static String? address(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse est requise';
    }

    if (value.length < 5) {
      return 'L\'adresse est trop courte';
    }

    return null;
  }

  /// Valide un poids (nombre positif)
  static String? weight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }

    final weight = double.tryParse(value);
    if (weight == null || weight <= 0) {
      return 'Poids invalide';
    }

    if (weight > 100) {
      return 'Poids maximum: 100 kg';
    }

    return null;
  }

  // Aliases pour compatibilité
  static String? validatePhone(String? value) => phoneNumber(value);
  static String? validatePassword(String? value) => password(value);
}
