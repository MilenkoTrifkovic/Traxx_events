class EmailInUseException implements Exception {
  final String message;
  EmailInUseException([this.message = 'Email is already in use']);

  @override
  String toString() => message;
}

class GuestLimitExceededException implements Exception {
  final String message;
  GuestLimitExceededException([this.message = 'Guest limit exceeded']);

  @override
  String toString() => message;
}
