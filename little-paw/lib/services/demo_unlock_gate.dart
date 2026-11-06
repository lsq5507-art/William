/// D2-04: demo simulatePurchase must only run after explicit user confirm.
class DemoUnlockGate {
  static Future<void> run({
    required bool confirmed,
    required Future<void> Function() unlock,
  }) async {
    if (!confirmed) return;
    await unlock();
  }
}
