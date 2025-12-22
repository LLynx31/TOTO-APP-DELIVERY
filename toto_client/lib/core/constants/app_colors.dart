import 'package:flutter/material.dart';

/// Palette de couleurs TOTO - Style Uber/Bolt
class AppColors {
  AppColors._();

  // Couleurs principales
  static const Color primary = Color(0xFF00C853);      // Vert - action, mouvement
  static const Color primaryLight = Color(0xFF5EFC82);
  static const Color primaryDark = Color(0xFF009624);

  static const Color secondary = Color(0xFF004E89);    // Bleu foncé - stabilité
  static const Color secondaryLight = Color(0xFF4A7AB8);
  static const Color secondaryDark = Color(0xFF00275C);

  static const Color accent = Color(0xFFFFD23F);       // Jaune doré - optimisme
  static const Color accentLight = Color(0xFFFFFF72);
  static const Color accentDark = Color(0xFFC8A100);

  // Couleurs de statut
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF1E88E5);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D5C61);
  static const Color textTertiary = Color(0xFF938E94);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Couleurs de fond
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);

  // Couleurs de bordure et divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Couleurs pour les cartes de livraison
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);

  // Couleurs de statut de livraison
  static const Color statusPending = Color(0xFFFFB300);
  static const Color statusAccepted = Color(0xFF1E88E5);
  static const Color statusPickupInProgress = Color(0xFF7B1FA2);
  static const Color statusPickedUp = Color(0xFF00ACC1);
  static const Color statusDeliveryInProgress = Color(0xFF43A047);
  static const Color statusDelivered = Color(0xFF00C853);
  static const Color statusCancelled = Color(0xFFE53935);

  // Couleurs pour les maps
  static const Color mapPickupMarker = Color(0xFF00C853);
  static const Color mapDeliveryMarker = Color(0xFFE53935);
  static const Color mapDriverMarker = Color(0xFF1E88E5);
  static const Color mapRouteColor = Color(0xFF00C853);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF004E89)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
  );
}
