/// Modèle pour gérer le quota de livraisons du livreur
class QuotaModel {
  final String id;
  final String delivererId;
  final int remainingDeliveries; // Nombre de livraisons restantes
  final int totalPurchased; // Total de livraisons achetées
  final DateTime lastUpdated;
  final List<QuotaPurchase> purchaseHistory;

  QuotaModel({
    required this.id,
    required this.delivererId,
    required this.remainingDeliveries,
    required this.totalPurchased,
    required this.lastUpdated,
    this.purchaseHistory = const [],
  });

  bool get hasQuota => remainingDeliveries > 0;

  bool get isLow => remainingDeliveries <= 2 && remainingDeliveries > 0;

  QuotaModel copyWith({
    String? id,
    String? delivererId,
    int? remainingDeliveries,
    int? totalPurchased,
    DateTime? lastUpdated,
    List<QuotaPurchase>? purchaseHistory,
  }) {
    return QuotaModel(
      id: id ?? this.id,
      delivererId: delivererId ?? this.delivererId,
      remainingDeliveries: remainingDeliveries ?? this.remainingDeliveries,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivererId': delivererId,
      'remainingDeliveries': remainingDeliveries,
      'totalPurchased': totalPurchased,
      'lastUpdated': lastUpdated.toIso8601String(),
      'purchaseHistory': purchaseHistory.map((p) => p.toJson()).toList(),
    };
  }

  factory QuotaModel.fromJson(Map<String, dynamic> json) {
    return QuotaModel(
      id: json['id'] as String,
      delivererId: json['delivererId'] as String,
      remainingDeliveries: json['remainingDeliveries'] as int,
      totalPurchased: json['totalPurchased'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      purchaseHistory: (json['purchaseHistory'] as List<dynamic>?)
              ?.map((p) => QuotaPurchase.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Modèle pour un achat de quota
class QuotaPurchase {
  final String id;
  final int deliveries; // Nombre de livraisons achetées
  final double price; // Prix payé en FCFA
  final QuotaPackType packType;
  final PaymentMethod paymentMethod;
  final DateTime purchasedAt;
  final bool isProcessed;

  QuotaPurchase({
    required this.id,
    required this.deliveries,
    required this.price,
    required this.packType,
    required this.paymentMethod,
    required this.purchasedAt,
    this.isProcessed = false,
  });

  QuotaPurchase copyWith({
    String? id,
    int? deliveries,
    double? price,
    QuotaPackType? packType,
    PaymentMethod? paymentMethod,
    DateTime? purchasedAt,
    bool? isProcessed,
  }) {
    return QuotaPurchase(
      id: id ?? this.id,
      deliveries: deliveries ?? this.deliveries,
      price: price ?? this.price,
      packType: packType ?? this.packType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliveries': deliveries,
      'price': price,
      'packType': packType.name,
      'paymentMethod': paymentMethod.name,
      'purchasedAt': purchasedAt.toIso8601String(),
      'isProcessed': isProcessed,
    };
  }

  factory QuotaPurchase.fromJson(Map<String, dynamic> json) {
    return QuotaPurchase(
      id: json['id'] as String,
      deliveries: json['deliveries'] as int,
      price: (json['price'] as num).toDouble(),
      packType: QuotaPackType.fromBackend(json['packType'] as String?),
      paymentMethod: PaymentMethod.fromBackend(json['paymentMethod'] as String?),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      isProcessed: json['isProcessed'] as bool? ?? false,
    );
  }
}

/// Types de packs de quota disponibles
/// Correspond aux types backend: basic, standard, premium
enum QuotaPackType {
  basic(deliveries: 10, price: 8000, discount: 0, validityDays: 30),
  standard(deliveries: 50, price: 35000, discount: 0.15, validityDays: 60),
  premium(deliveries: 100, price: 60000, discount: 0.25, validityDays: 90);

  final int deliveries;
  final double price;
  final double discount;
  final int validityDays;

  const QuotaPackType({
    required this.deliveries,
    required this.price,
    required this.discount,
    required this.validityDays,
  });

  /// Prix par livraison
  double get pricePerDelivery => price / deliveries;

  String get displayName {
    switch (this) {
      case QuotaPackType.basic:
        return 'Pack Basic';
      case QuotaPackType.standard:
        return 'Pack Standard';
      case QuotaPackType.premium:
        return 'Pack Premium';
    }
  }

  String get description {
    switch (this) {
      case QuotaPackType.basic:
        return '10 courses - Idéal pour débuter';
      case QuotaPackType.standard:
        return '50 courses - Économisez 15%';
      case QuotaPackType.premium:
        return '100 courses - Économisez 25%';
    }
  }

  String get badgeText {
    switch (this) {
      case QuotaPackType.basic:
        return 'Découverte';
      case QuotaPackType.standard:
        return '-15%';
      case QuotaPackType.premium:
        return 'Meilleure valeur';
    }
  }

  /// Nom du type pour le backend
  String get backendName => name;

  /// Crée depuis le nom backend
  static QuotaPackType fromBackend(String? typeName) {
    switch (typeName?.toLowerCase()) {
      case 'basic':
        return QuotaPackType.basic;
      case 'standard':
        return QuotaPackType.standard;
      case 'premium':
        return QuotaPackType.premium;
      default:
        return QuotaPackType.basic;
    }
  }
}

/// Méthodes de paiement disponibles
/// Note: Chaque opérateur mobile est une méthode distincte
enum PaymentMethod {
  orangeMoney,
  mtnMoney,
  moovMoney,
  wave;

  String get displayName {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMoney:
        return 'MTN Mobile Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.wave:
        return 'Wave';
    }
  }

  /// Nom court pour affichage compact
  String get shortName {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange';
      case PaymentMethod.mtnMoney:
        return 'MTN';
      case PaymentMethod.moovMoney:
        return 'Moov';
      case PaymentMethod.wave:
        return 'Wave';
    }
  }

  /// Couleur de la marque
  int get brandColor {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 0xFFFF6600; // Orange
      case PaymentMethod.mtnMoney:
        return 0xFFFFCC00; // Jaune MTN
      case PaymentMethod.moovMoney:
        return 0xFF0066CC; // Bleu Moov
      case PaymentMethod.wave:
        return 0xFF1DC7EA; // Bleu Wave
    }
  }

  /// Nom pour le backend
  String get backendName {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'orange_money';
      case PaymentMethod.mtnMoney:
        return 'mtn_money';
      case PaymentMethod.moovMoney:
        return 'moov_money';
      case PaymentMethod.wave:
        return 'wave';
    }
  }

  /// Parse depuis le backend
  static PaymentMethod fromBackend(String? name) {
    switch (name?.toLowerCase()) {
      case 'orange_money':
        return PaymentMethod.orangeMoney;
      case 'mtn_money':
        return PaymentMethod.mtnMoney;
      case 'moov_money':
        return PaymentMethod.moovMoney;
      case 'wave':
        return PaymentMethod.wave;
      default:
        return PaymentMethod.orangeMoney;
    }
  }
}
