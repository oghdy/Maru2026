/// True only in the web demo build (`flutter build web --dart-define=DEMO_MODE=true`).
/// A compile-time constant: in every other build the demo branches are removed by the compiler,
/// so the iOS and Android apps behave as if this code did not exist.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE');
