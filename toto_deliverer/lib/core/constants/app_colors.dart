import 'package:flutter/material.dart';

/// Couleurs de l'application TOTO Deliverer - Palette "Green Rider"
/// Énergique, fraîche, parfaite pour les livreurs
class AppColors {
  AppColors._();

  // Couleurs principales (Vert pour livreurs)
  static const Color primary = Color(0xFF00C853); // Vert vif (action, mouvement, GO!)
  static const Color primaryDark = Color(0xFF00A843);
  static const Color primaryLight = Color(0xFF5EFC82);

  // Couleurs secondaires
  static const Color secondary = Color(0xFF004E89); // Bleu foncé (stabilité, confiance, compatible client)
  static const Color secondaryDark = Color(0xFF003A66);
  static const Color secondaryLight = Color(0xFF0066A8);

  // Couleurs d'accent
  static const Color accent = Color(0xFFFFD23F); // Jaune doré (cohérent avec app client)
  static const Color accentLight = Color(0xFFFFDD6B);

  // Couleurs de statut
  static const Color success = Color(0xFF00C853); // Vert vif (cohérent avec primary)
  static const Color error = Color(0xFFF44336); // Rouge vif
  static const Color warning = Color(0xFFFFD23F); // Jaune doré
  static const Color info = Color(0xFF004E89); // Bleu foncé

  // Couleurs de texte (Light Mode)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D5C61);
  static const Color textTertiary = Color(0xFF938E94);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Couleurs de texte (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textTertiaryDark = Color(0xFF808080);

  // Couleurs de fond (Light Mode)
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF5F5F5);

  // Couleurs de fond (Dark Mode)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundGreyDark = Color(0xFF1A1A1A);

  // Couleurs des cartes et surfaces (Light Mode)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFFAFAFA);

  // Couleurs des cartes et surfaces (Dark Mode)
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceGreyDark = Color(0xFF2D2D2D);
  static const Color surfaceElevatedDark = Color(0xFF383838);

  // Couleurs des bordures (Light Mode)
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFFBDBDBD);

  // Couleurs des bordures (Dark Mode)
  static const Color borderDarkMode = Color(0xFF404040);
  static const Color borderDarkModeStrong = Color(0xFF505050);

  // Couleurs des ombres
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // Couleurs des badges de statut de course
  static const Color courseAvailable = Color(0xFF00C853); // Vert
  static const Color courseInProgress = Color(0xFFFFD23F); // Jaune
  static const Color courseCompleted = Color(0xFF004E89); // Bleu
  static const Color courseCancelled = Color(0xFFF44336); // Rouge

  // Couleurs spécifiques livreurs
  static const Color online = Color(0xFF00C853); // Statut en ligne (vert)
  static const Color offline = Color(0xFF9E9E9E); // Statut hors ligne (gris)
  static const Color quota = Color(0xFF00C853); // Quota disponible (vert)
  static const Color quotaLow = Color(0xFFFFD23F); // Quota faible (jaune)
  static const Color quotaEmpty = Color(0xFFF44336); // Quota épuisé (rouge)

  // Couleurs des modes de livraison
  static const Color standard = Color(0xFF004E89); // Mode standard (bleu)
  static const Color express = Color(0xFFFFD23F); // Mode express (jaune, urgence)

  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
