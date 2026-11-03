/// Formal interest options — MUST NOT unlock membership.
enum IntentChoice {
  monthly,
  yearly,
  card,
  book,
  none,
}

extension IntentChoiceX on IntentChoice {
  String get eventValue {
    switch (this) {
      case IntentChoice.monthly:
        return 'monthly';
      case IntentChoice.yearly:
        return 'yearly';
      case IntentChoice.card:
        return 'card';
      case IntentChoice.book:
        return 'book';
      case IntentChoice.none:
        return 'none';
    }
  }
}
