/// App-wide configuration, set per build with `--dart-define`.
///
/// ```sh
/// # Production API (default)
/// flutter run
///
/// # Local backend from the Android emulator
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
/// ```
///
/// See README for every available key.
abstract class AppConfig {
  AppConfig._();

  /// Base URL of the backend API, without a trailing slash.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-neocentral.fathur.site',
  );

  /// App version shown on Tentang Aplikasi. Keep the default equal to
  /// `version` in pubspec.yaml (a test checks it).
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // ── Microsoft Entra ID (Azure AD) ───────────────────────────
  // Public identifiers of the NeoCentral app registration, not secrets.
  // Sign-in runs through the backend's Microsoft OAuth flow, which uses the
  // backend's own registration; these values document it and can be
  // overridden per build.

  /// Application (client) ID.
  static const String msClientId = String.fromEnvironment(
    'MS_CLIENT_ID',
    defaultValue: 'c7b60d58-43f3-48cd-90a6-f74c87f1b324',
  );

  /// Directory (tenant) ID.
  static const String msTenantId = String.fromEnvironment(
    'MS_TENANT_ID',
    defaultValue: '281f26cd-2904-4669-935e-018857035410',
  );

  /// Backend endpoint that starts Microsoft sign-in.
  static String get microsoftLoginUrl => '$baseUrl/auth/microsoft/login';
}
