class QuotaPackageModel {
  final String id;
  final String name;
  final int deliveries;
  final double priceUsd;
  final int? validityDays;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuotaPackageModel({
    required this.id,
    required this.name,
    required this.deliveries,
    required this.priceUsd,
    this.validityDays,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuotaPackageModel.fromJson(Map<String, dynamic> json) {
    return QuotaPackageModel(
      id: json['id'],
      name: json['name'],
      deliveries: json['deliveries'],
      priceUsd: double.parse(json['price_usd'].toString()),
      validityDays: json['validity_days'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deliveries': deliveries,
      'price_usd': priceUsd,
      'validity_days': validityDays,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ClientQuotaModel {
  final String id;
  final String clientId;
  final String packageId;
  final int totalDeliveries;
  final int usedDeliveries;
  final int remainingDeliveries;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime purchasedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QuotaPackageModel? package;

  ClientQuotaModel({
    required this.id,
    required this.clientId,
    required this.packageId,
    required this.totalDeliveries,
    required this.usedDeliveries,
    required this.remainingDeliveries,
    this.expiresAt,
    required this.isActive,
    required this.purchasedAt,
    required this.createdAt,
    required this.updatedAt,
    this.package,
  });

  factory ClientQuotaModel.fromJson(Map<String, dynamic> json) {
    return ClientQuotaModel(
      id: json['id'],
      clientId: json['client_id'],
      packageId: json['package_id'],
      totalDeliveries: json['total_deliveries'],
      usedDeliveries: json['used_deliveries'],
      remainingDeliveries: json['remaining_deliveries'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isActive: json['is_active'] ?? false,
      purchasedAt: DateTime.parse(json['purchased_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      package: json['package'] != null
          ? QuotaPackageModel.fromJson(json['package'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'package_id': packageId,
      'total_deliveries': totalDeliveries,
      'used_deliveries': usedDeliveries,
      'remaining_deliveries': remainingDeliveries,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'purchased_at': purchasedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (package != null) 'package': package!.toJson(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get hasRemainingDeliveries => remainingDeliveries > 0;
}

enum QuotaUsageAction {
  use,
  refund,
}

class QuotaUsageHistoryModel {
  final String id;
  final String quotaId;
  final String? deliveryId;
  final QuotaUsageAction action;
  final int quantity;
  final String? reason;
  final DateTime createdAt;

  QuotaUsageHistoryModel({
    required this.id,
    required this.quotaId,
    this.deliveryId,
    required this.action,
    required this.quantity,
    this.reason,
    required this.createdAt,
  });

  factory QuotaUsageHistoryModel.fromJson(Map<String, dynamic> json) {
    return QuotaUsageHistoryModel(
      id: json['id'],
      quotaId: json['quota_id'],
      deliveryId: json['delivery_id'],
      action: json['action'] == 'use'
          ? QuotaUsageAction.use
          : QuotaUsageAction.refund,
      quantity: json['quantity'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get actionLabel {
    switch (action) {
      case QuotaUsageAction.use:
        return 'Utilisé';
      case QuotaUsageAction.refund:
        return 'Remboursé';
    }
  }
}
