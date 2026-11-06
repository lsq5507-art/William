/// Feature gates for role-gen-web-v0.17.
/// Custom character = local pipeline (on).
/// Image gen = fail-closed until AI stack is confirmed without new paid keys.
class RoleGenCapabilities {
  /// Local create/save/select — no external API.
  static const bool customCharacterEnabled = true;

  /// True only when a real image model is wired and confirmed usable.
  /// Currently false: pubspec has no firebase_ai; no new paid API authorized.
  static const bool imageGenEnabled = false;
}
