/// AI features (summaries, quizzes, Q&A) are deliberately NOT implemented
/// in v1 -- this file only defines the seam. [NoopAiProvider] is what's
/// wired up today: every call resolves instantly with an "unavailable"
/// result rather than throwing, so UI that calls it can't crash even
/// before a real provider exists. Adding real AI later is: implement
/// this interface (e.g. `CloudAiProvider` calling a hosted LLM), then
/// swap it in behind `aiProviderProvider` -- no feature code changes.
abstract class AiProvider {
  Future<String?> summarize(String documentText);
}

class NoopAiProvider implements AiProvider {
  @override
  Future<String?> summarize(String documentText) async => null;
}
