/// Parsed voice command category.
enum VoiceIntentType {
  sale,
  purchase,
  paymentReceived,
  paymentPaid,
  expense,
  createParty,
  createItem,
  unknown,
}

extension VoiceIntentTypeLabels on VoiceIntentType {
  String get hindiLabel => switch (this) {
        VoiceIntentType.sale => 'Bikri',
        VoiceIntentType.purchase => 'Kharid',
        VoiceIntentType.paymentReceived => 'Paisa Mila',
        VoiceIntentType.paymentPaid => 'Paisa Diya',
        VoiceIntentType.expense => 'Kharch',
        VoiceIntentType.createParty => 'Nayi Party',
        VoiceIntentType.createItem => 'Naya Maal',
        VoiceIntentType.unknown => 'Samajh nahi aaya',
      };
}
