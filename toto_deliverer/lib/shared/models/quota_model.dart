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
      packType: QuotaPackType.values.firstWhere(
        (e) => e.name == json['packType'],
        orElse: () => QuotaPackType.pack5,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.mobileMoney,
      ),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      isProcessed: json['isProcessed'] as bool? ?? false,
    );
  }
}

/// Types de packs de quota disponibles
enum QuotaPackType {
  pack5(deliveries: 5, price: 5000, discount: 0),
  pack10(deliveries: 10, price: 9500, discount: 0.05),
  pack20(deliveries: 20, price: 18000, discount: 0.10);

  final int deliveries;
  final double price;
  final double discount;

  const QuotaPackType({
    required this.deliveries,
    required this.price,
    required this.discount,
  });

  String get displayName {
    switch (this) {
      case QuotaPackType.pack5:
        return 'Pack 5 livraisons';
      case QuotaPackType.pack10:
        return 'Pack 10 livraisons';
      case QuotaPackType.pack20:
        return 'Pack 20 livraisons';
    }
  }

  String get badgeText {
    switch (this) {
      case QuotaPackType.pack5:
        return 'Recommandé';
      case QuotaPackType.pack10:
        return '-5%';
      case QuotaPackType.pack20:
        return 'Meilleure valeur';
    }
  }
}

/// Méthodes de paiement disponibles
enum PaymentMethod {
  mobileMoney,
  bankTransfer,
  cash;

  String get displayName {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Virement Bancaire';
      case PaymentMethod.cash:
        return 'Espèces';
    }
  }
}
