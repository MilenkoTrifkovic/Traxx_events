import 'dart:math';

/// Generates a random invitation code in the format: WE2390RT
/// 
/// Format:
/// - 2 uppercase letters (WE)
/// - 4 digits (2390)
/// - 2 uppercase letters (RT)
/// 
/// Example: WE2390RT, AB1234CD, XY9876ZW
String generateInvitationCode() {
  final random = Random();
  
  // Generate 2 random uppercase letters
  String getRandomLetters(int count) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return List.generate(count, (_) => letters[random.nextInt(letters.length)]).join();
  }
  
  // Generate 4 random digits
  String getRandomDigits(int count) {
    return List.generate(count, (_) => random.nextInt(10).toString()).join();
  }
  
  // Format: 2 letters + 4 digits + 2 letters
  final firstPart = getRandomLetters(2);
  final numberPart = getRandomDigits(4);
  final lastPart = getRandomLetters(2);
  
  return '$firstPart$numberPart$lastPart';
}
