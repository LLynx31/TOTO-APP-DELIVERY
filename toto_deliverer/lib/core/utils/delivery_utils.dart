/// Utilitaires pour les livraisons
class DeliveryUtils {
  /// Formate l'ID de livraison pour l'affichage
  /// Retourne les 8 premiers caractères si l'ID est plus long,
  /// sinon retourne l'ID complet
  static String formatDeliveryId(String id) {
    if (id.length > 8) {
      return id.substring(0, 8);
    }
    return id;
  }

  /// Formate l'ID de livraison avec le préfixe "Course #"
  static String formatDeliveryIdWithPrefix(String id) {
    return 'Course #${formatDeliveryId(id)}';
  }
}
