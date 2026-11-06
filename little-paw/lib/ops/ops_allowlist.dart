/// Compile-time allowlist + optional Firestore `ops/allowlist.emails`.
///
/// Audit note (LP-DEV-21): default seed `lsq5507@gmail.com`. Runtime extras
/// come from Firestore doc `ops/allowlist` field `emails` (list of lowercase
/// strings). Changes to the Firestore list are console-auditable; compile-time
/// edits require a rebuild. Rules mirror both sources for `users/**` read.
class OpsAllowlist {
  OpsAllowlist._();

  static const List<String> compileTimeEmails = [
    'lsq5507@gmail.com',
  ];

  static bool isAllowlisted(
    String? email, {
    List<String> firestoreEmails = const [],
  }) {
    if (email == null) return false;
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return false;
    for (final x in compileTimeEmails) {
      if (x.trim().toLowerCase() == e) return true;
    }
    for (final x in firestoreEmails) {
      if (x.trim().toLowerCase() == e) return true;
    }
    return false;
  }
}
