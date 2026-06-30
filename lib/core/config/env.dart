/// Runtime environment configuration.
enum AppEnvironment {
  development,
  staging,
  production,
}

abstract final class Env {
  static const AppEnvironment environment = AppEnvironment.development;

  static bool get isProduction => environment == AppEnvironment.production;
}
