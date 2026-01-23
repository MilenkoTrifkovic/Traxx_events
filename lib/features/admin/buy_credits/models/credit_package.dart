class CreditPackage {
  final String name;
  final int events; // Number of events
  final int price; // in cents
  final int? totalPrice; // Total price for display
  final int? savings; // Savings amount
  final String description;
  final bool isPopular;
  final List<String> features;
  final String? stripePriceId; // Stripe Price ID for checkout

  CreditPackage({
    required this.name,
    required this.events,
    required this.price,
    this.totalPrice,
    this.savings,
    required this.description,
    this.isPopular = false,
    required this.features,
    this.stripePriceId,
  });

  String get priceFormatted => '\$${(price / 100).toStringAsFixed(0)}';
  String get totalPriceFormatted =>
      totalPrice != null ? '\$${(totalPrice! / 100).toStringAsFixed(0)}' : '';
  String get savingsFormatted =>
      savings != null ? '\$${(savings! / 100).toStringAsFixed(0)}' : '';
  double get pricePerEvent => (price / 100) / events;
}
