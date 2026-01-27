class PaymentTransaction {
  final String id;
  final String transactionId;
  final String organisationId;
  final int events;
  final int amount;
  final String currency;
  final String paymentStatus;
  final String packageName;
  final String userEmail;
  final String userId;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final bool isDisabled;
  
  // Free credit fields
  final bool isAssignedBySuperAdmin;
  final bool isFreeCredit;
  final String? assignedByEmail;
  final String? assignedByName;
  final String? note;

  PaymentTransaction({
    required this.id,
    required this.transactionId,
    required this.organisationId,
    required this.events,
    required this.amount,
    required this.currency,
    required this.paymentStatus,
    required this.packageName,
    required this.userEmail,
    required this.userId,
    required this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
    this.isAssignedBySuperAdmin = false,
    this.isFreeCredit = false,
    this.assignedByEmail,
    this.assignedByName,
    this.note,
  });

  /// Check if this is a free credit (gifted by super admin)
  bool get isFree => isAssignedBySuperAdmin || isFreeCredit || amount == 0;

  /// Get display source - who made the payment or who assigned the credit
  String get displaySource {
    if (isAssignedBySuperAdmin) {
      return assignedByName ?? assignedByEmail ?? 'Trax Admin';
    }
    return userEmail;
  }

  /// Get display package name with "Free" prefix for gifts
  String get displayPackageName {
    if (isFree) {
      return 'Free Events Gift';
    }
    return packageName;
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      organisationId: json['organisationId'] ?? '',
      events: json['events'] ?? 0,
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'usd',
      paymentStatus: json['paymentStatus'] ?? '',
      packageName: json['packageName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'])
          : null,
      isDisabled: json['isDisabled'] ?? false,
      // Free credit fields
      isAssignedBySuperAdmin: json['isAssignedBySuperAdmin'] ?? false,
      isFreeCredit: json['isFreeCredit'] ?? false,
      assignedByEmail: json['assignedByEmail'],
      assignedByName: json['assignedByName'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'organisationId': organisationId,
      'events': events,
      'amount': amount,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'packageName': packageName,
      'userEmail': userEmail,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'isDisabled': isDisabled,
      'isAssignedBySuperAdmin': isAssignedBySuperAdmin,
      'isFreeCredit': isFreeCredit,
      if (assignedByEmail != null) 'assignedByEmail': assignedByEmail,
      if (assignedByName != null) 'assignedByName': assignedByName,
      if (note != null) 'note': note,
    };
  }

  String get amountFormatted {
    if (isFree) {
      return 'Free';
    }
    return '\$${(amount / 100).toStringAsFixed(2)}';
  }

  String get statusFormatted {
    if (isFree) {
      return 'Gift';
    }
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'complete':
      case 'succeeded':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus;
    }
  }
}
