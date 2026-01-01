import 'dart:math';

/// Generates a random 6-digit batch ID.
/// 
/// Format: 6 digits (e.g., 123456, 789012, 000001)
/// 
/// Range: 000000 to 999999 (1,000,000 possible combinations)
/// 
/// Examples: 123456, 789012, 000001, 999999
String generateBatchId() {
  final random = Random();
  
  // Generate a random number between 0 and 999999
  final number = random.nextInt(1000000);
  
  // Format with leading zeros to ensure 6 digits
  return number.toString().padLeft(6, '0');
}
