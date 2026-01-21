class CreditPackage {
  final int credits;
  final int price; // in cents
  final String description;
  final bool isPopular;
  final String? stripePriceId; // Stripe Price ID for checkout

  CreditPackage({
    required this.credits,
    required this.price,
    required this.description,
    this.isPopular = false,
    this.stripePriceId,
  });
  
  String get priceFormatted => '\$${(price / 100).toStringAsFixed(2)}';
  double get pricePerCredit => (price / 100) / credits;
}
