import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Configuration d'environnement pour l'app livreur
enum Environment { development, staging, production }

class EnvConfig {
  EnvConfig._();

  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  /// Retourne l'URL de développement appropriée selon la plateforme
  static String get _developmentUrl {
    if (kIsWeb) {
      // Pour web, utiliser localhost
      return 'http://localhost:3000';
    } else {
      // Pour mobile
      try {
        if (Platform.isAndroid) {
          // Android emulator utilise 10.0.2.2 pour accéder au localhost de l'hôte
          return 'http://10.0.2.2:3000';
        } else if (Platform.isIOS) {
          // iOS simulator peut utiliser localhost
          return 'http://localhost:3000';
        }
      } catch (e) {
        // Si Platform n'est pas disponible, fallback sur localhost
        return 'http://localhost:3000';
      }
      // Fallback par défaut
      return 'http://localhost:3000';
    }
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return _developmentUrl;
      case Environment.staging:
        return 'https://staging-api.toto.ci';
      case Environment.production:
        return 'https://api.toto.ci';
    }
  }

  static String get socketUrl {
    switch (_environment) {
      case Environment.development:
        return _developmentUrl;
      case Environment.staging:
        return 'https://staging-api.toto.ci';
      case Environment.production:
        return 'https://api.toto.ci';
    }
  }

  static String get googleMapsApiKey {
    // TODO: Remplacer par vos vraies clés API
    switch (_environment) {
      case Environment.development:
        return 'YOUR_DEV_GOOGLE_MAPS_API_KEY';
      case Environment.staging:
        return 'YOUR_STAGING_GOOGLE_MAPS_API_KEY';
      case Environment.production:
        return 'YOUR_PROD_GOOGLE_MAPS_API_KEY';
    }
  }

  static bool get enableLogging => !isProduction;
  static bool get enableCrashlytics => isProduction;

  /// Feature flags pour l'intégration backend

  /// Active le mode simulation (données mockées)
  /// - true: utilise SimulationService (pas de backend)
  /// - false: utilise les vraies API backend
  static const bool enableSimulationMode = false;

  /// Active les vrais paiements (Mobile Money, etc.)
  /// - true: intégration avec gateway de paiement réel
  /// - false: simulation de paiement uniquement
  static const bool useRealPayments = false;

  /// Timeout pour les requêtes API (en secondes)
  static const int apiTimeout = 30;

  /// Timeout pour la connexion API (en secondes)
  static const int connectTimeout = 30;
}
