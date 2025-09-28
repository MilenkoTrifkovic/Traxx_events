enum ServiceType {
  buffet(
      "Buffet: Guests serve themselves from a variety of dishes. When guests responding to the invitation, they can only see what food is served in buffet"),
  plated(
      "plated: Food is served on plated directly at the table. Event creator can choose if guests can choose their meal in invitation response");

  final String description;

  const ServiceType(this.description);
}
