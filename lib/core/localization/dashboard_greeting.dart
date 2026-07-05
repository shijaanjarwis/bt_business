import 'assistant_language.dart';

/// Saved dashboard greeting styles — extend when more greetings are added.
enum DashboardGreetingStyle {
  assalamualaikumNamaste('assalamualaikum_namaste');

  const DashboardGreetingStyle(this.storageCode);

  final String storageCode;

  static DashboardGreetingStyle? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final style in DashboardGreetingStyle.values) {
      if (style.storageCode == code) return style;
    }
    return null;
  }

  /// Default greeting for new installs and unknown saved values.
  static const DashboardGreetingStyle defaultStyle =
      DashboardGreetingStyle.assalamualaikumNamaste;
}

/// Two-line dashboard greeting — primary line plus optional subtitle in parentheses.
class DashboardGreetingDisplay {
  const DashboardGreetingDisplay({
    required this.primary,
    this.secondary,
  });

  final String primary;
  final String? secondary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardGreetingDisplay &&
          primary == other.primary &&
          secondary == other.secondary;

  @override
  int get hashCode => Object.hash(primary, secondary);
}

/// Approved dashboard greetings — never load from JSON (prevents Welcome drift).
abstract final class DashboardGreetingCopy {
  static const assalamualaikumNamaste = DashboardGreetingDisplay(
    primary: 'Assalamualaikum',
    secondary: 'Namaste',
  );

  static const assalamualaikumNamasteHindi = DashboardGreetingDisplay(
    primary: 'अस्सलामु अलैकुम',
    secondary: 'नमस्ते',
  );

  static const urdu = DashboardGreetingDisplay(
    primary: 'السلام علیکم',
  );

  /// Greetings that must never appear in the product.
  static const List<String> forbidden = [
    'Welcome',
    'Good Morning',
    'Good Afternoon',
    'Good Evening',
  ];

  static DashboardGreetingDisplay forStyle(
    DashboardGreetingStyle style, {
    AssistantLanguage language = AssistantLanguage.english,
  }) {
    return switch (style) {
      DashboardGreetingStyle.assalamualaikumNamaste =>
        switch (language) {
          AssistantLanguage.hindi => assalamualaikumNamasteHindi,
          AssistantLanguage.urdu => urdu,
          AssistantLanguage.english => assalamualaikumNamaste,
        },
    };
  }
}
