import '../errors/failures.dart';

/// Maps thrown errors and failures to safe Hindi-first user messages.
abstract final class UserErrorMessages {
  static const generic =
      'Kuch galat ho gaya. Phir se try karein ya app dubara kholen.';

  static String from(Object error) {
    if (error is Failure) {
      return error.message.trim().isEmpty ? generic : error.message;
    }
    return generic;
  }
}
