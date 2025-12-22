import 'package:intl/intl.dart';

/// Formateurs de données
class Formatters {
  Formatters._();

  // ==================
  // Currency
  // ==================

  /// Formate un montant en FCFA
  static String currency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  /// Formate un montant court (ex: 3.5k)
  static String currencyShort(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k FCFA';
    }
    return '${amount.round()} FCFA';
  }

  // ==================
  // Phone
  // ==================

  /// Formate un numéro de téléphone pour l'affichage
  /// Input: +2250712345678
  /// Output: +225 07 12 34 56 78
  static String phoneNumber(String phone) {
    if (phone.length < 13) return phone;

    final prefix = phone.substring(0, 4); // +225
    final rest = phone.substring(4);

    final buffer = StringBuffer(prefix);
    for (var i = 0; i < rest.length; i++) {
      if (i % 2 == 0) buffer.write(' ');
      buffer.write(rest[i]);
    }

    return buffer.toString();
  }

  /// Nettoie un numéro de téléphone
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  // ==================
  // Date & Time
  // ==================

  /// Formate une date (ex: 28 nov. 2024)
  static String date(DateTime date) {
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  }

  /// Formate une date courte (ex: 28/11/24)
  static String dateShort(DateTime date) {
    return DateFormat('dd/MM/yy', 'fr_FR').format(date);
  }

  /// Formate une heure (ex: 14:30)
  static String time(DateTime date) {
    return DateFormat('HH:mm', 'fr_FR').format(date);
  }

  /// Formate une date et heure (ex: 28 nov. 2024 à 14:30)
  static String dateTime(DateTime date) {
    return DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(date);
  }

  /// Formate une durée relative (ex: il y a 5 min)
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays}j';
    } else {
      return Formatters.date(date);
    }
  }

  /// Formate un ETA (ex: 12 min)
  static String eta(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
    }
  }

  // ==================
  // Distance
  // ==================

  /// Formate une distance en km
  static String distance(double kilometers) {
    if (kilometers < 1) {
      return '${(kilometers * 1000).round()} m';
    }
    return '${kilometers.toStringAsFixed(1)} km';
  }

  // ==================
  // Delivery Status
  // ==================

  /// Traduit un statut de livraison
  static String deliveryStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'pickupinprogress':
        return 'En route vers enlèvement';
      case 'pickedup':
        return 'Colis récupéré';
      case 'deliveryinprogress':
        return 'En cours de livraison';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  // ==================
  // Quota
  // ==================

  /// Formate le nombre de jours restants
  static String remainingDays(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expiré';
    } else if (difference.inDays == 0) {
      return 'Expire aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Expire demain';
    } else {
      return '${difference.inDays} jours restants';
    }
  }

  // ==================
  // Misc
  // ==================

  /// Tronque un texte
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalise la première lettre
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
