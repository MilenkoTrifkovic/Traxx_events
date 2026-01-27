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
  });

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
    };
  }

  String get amountFormatted => '\$${(amount / 100).toStringAsFixed(2)}';

  String get statusFormatted {
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
