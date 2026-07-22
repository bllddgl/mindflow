/// Feature flag scaffold for Free vs. Premium.
///
/// Every premium-gated feature should check `entitlements.has(...)` from
/// day one -- retrofitting this after many features exist is expensive,
/// doing it now is nearly free. v1 has no real paywall yet, so
/// [LocalEntitlementProvider] grants everything; swapping in a real
/// billing-backed implementation later doesn't touch any feature code.
enum Feature { unlimitedLibrary, aiSummaries, aiQuiz, vocabularyDeck }

abstract class EntitlementProvider {
  bool has(Feature feature);
}

class LocalEntitlementProvider implements EntitlementProvider {
  @override
  bool has(Feature feature) => true; // v1: everything unlocked.
}
