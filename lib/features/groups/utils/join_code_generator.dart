import 'dart:math';

/// Utility class for generating random join codes
class JoinCodeGenerator {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _random = Random();

  /// Generates a random 5-character join code with mixed letters and numbers
  /// 
  /// Format: Mix of uppercase letters (A-Z) and numbers (0-9)
  /// Length: Exactly 5 characters
  /// Example: "A7K2M", "X9B4C", "L5P8Q"
  static String generate() {
    return String.fromCharCodes(
      Iterable.generate(
        5,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }

  /// Validates if a join code matches the expected format
  /// 
  /// Returns true if the code is exactly 5 characters and contains only
  /// uppercase letters and numbers
  static bool isValidFormat(String code) {
    if (code.length != 5) return false;
    
    final regex = RegExp(r'^[A-Z0-9]{5}$');
    return regex.hasMatch(code);
  }

  /// Generates a unique join code that doesn't exist in the provided set
  /// 
  /// Used to ensure uniqueness when creating new groups
  static String generateUnique(Set<String> existingCodes) {
    String code;
    int attempts = 0;
    const maxAttempts = 100;

    do {
      code = generate();
      attempts++;
      
      if (attempts > maxAttempts) {
        // Fallback: append random number to ensure uniqueness
        code = generate() + _random.nextInt(10).toString();
        break;
      }
    } while (existingCodes.contains(code));

    return code;
  }
}
