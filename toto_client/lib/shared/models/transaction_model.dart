enum TransactionType {
  recharge,
  withdrawal,
  payment;

  String get displayName {
    switch (this) {
      case TransactionType.recharge:
        return 'Recharge';
      case TransactionType.withdrawal:
        return 'Retrait';
      case TransactionType.payment:
        return 'Paiement';
    }
  }
}

enum PaymentMethod {
  mobileMoney,
  bankCard,
  cash;

  String get displayName {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankCard:
        return 'Carte Bancaire';
      case PaymentMethod.cash:
        return 'Espèces';
    }
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? description;
  final String? deliveryId;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    this.description,
    this.deliveryId,
    required this.createdAt,
  });

  String get formattedAmount {
    final sign = type == TransactionType.recharge ? '+' : '-';
    return '$sign${amount.toStringAsFixed(0)} FCFA';
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.payment,
      ),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.mobileMoney,
      ),
      description: json['description'] as String?,
      deliveryId: json['deliveryId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'description': description,
      'deliveryId': deliveryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    PaymentMethod? paymentMethod,
    String? description,
    String? deliveryId,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      deliveryId: deliveryId ?? this.deliveryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
