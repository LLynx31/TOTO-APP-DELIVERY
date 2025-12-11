import 'quota_model.dart';

/// Modèle pour les transactions du portefeuille du livreur
class TransactionModel {
  final String id;
  final String delivererId;
  final TransactionType type;
  final double amount; // Montant en FCFA
  final DateTime timestamp;
  final String? description;
  final String? relatedCourseId; // ID de la course liée (pour les gains)
  final String? relatedQuotaPurchaseId; // ID de l'achat de quota lié
  final PaymentMethod? paymentMethod;
  final TransactionStatus status;

  TransactionModel({
    required this.id,
    required this.delivererId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.description,
    this.relatedCourseId,
    this.relatedQuotaPurchaseId,
    this.paymentMethod,
    this.status = TransactionStatus.completed,
  });

  bool get isCredit => type == TransactionType.courseEarning;
  bool get isDebit => type == TransactionType.withdrawal || type == TransactionType.quotaPurchase;

  TransactionModel copyWith({
    String? id,
    String? delivererId,
    TransactionType? type,
    double? amount,
    DateTime? timestamp,
    String? description,
    String? relatedCourseId,
    String? relatedQuotaPurchaseId,
    PaymentMethod? paymentMethod,
    TransactionStatus? status,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      delivererId: delivererId ?? this.delivererId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      relatedCourseId: relatedCourseId ?? this.relatedCourseId,
      relatedQuotaPurchaseId: relatedQuotaPurchaseId ?? this.relatedQuotaPurchaseId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivererId': delivererId,
      'type': type.name,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'relatedCourseId': relatedCourseId,
      'relatedQuotaPurchaseId': relatedQuotaPurchaseId,
      'paymentMethod': paymentMethod?.name,
      'status': status.name,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      delivererId: json['delivererId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.courseEarning,
      ),
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
      relatedCourseId: json['relatedCourseId'] as String?,
      relatedQuotaPurchaseId: json['relatedQuotaPurchaseId'] as String?,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == json['paymentMethod'],
              orElse: () => PaymentMethod.mobileMoney,
            )
          : null,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.completed,
      ),
    );
  }
}

/// Types de transactions
enum TransactionType {
  courseEarning, // Gain de livraison (crédit)
  withdrawal, // Retrait (débit)
  quotaPurchase; // Achat de quota (débit)

  String get displayName {
    switch (this) {
      case TransactionType.courseEarning:
        return 'Gain de course';
      case TransactionType.withdrawal:
        return 'Retrait';
      case TransactionType.quotaPurchase:
        return 'Achat de quota';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.courseEarning:
        return '💰';
      case TransactionType.withdrawal:
        return '📤';
      case TransactionType.quotaPurchase:
        return '🔄';
    }
  }
}

/// Statuts de transaction
enum TransactionStatus {
  pending, // En attente
  completed, // Terminée
  failed, // Échouée
  cancelled; // Annulée

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Terminée';
      case TransactionStatus.failed:
        return 'Échouée';
      case TransactionStatus.cancelled:
        return 'Annulée';
    }
  }
}
