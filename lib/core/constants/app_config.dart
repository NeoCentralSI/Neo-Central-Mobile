/// App-wide configuration constants
abstract class AppConfig {
  AppConfig._();

  /// Base URL of the backend API.
  /// Change this to your server IP when running on a physical device.
  /// For emulator use 10.0.2.2 (Android) or localhost (iOS simulator).
  static const String baseUrl = 'http://10.44.9.138:3000';

  // ── Microsoft Azure OAuth2 credentials ──────────────────────
  /// Application (client) ID from Azure portal
  static const String msClientId = 'c7b60d58-43f3-48cd-90a6-f74c87f1b324';

  /// Azure AD Tenant ID
  static const String msTenantId = '281f26cd-2904-4669-935e-018857035410';

  /// Discovery document URL for OpenID Connect metadata
  static const String msDiscoveryUrl =
      'https://login.microsoftonline.com/281f26cd-2904-4669-935e-018857035410/v2.0/.well-known/openid-configuration';

  /// Redirect URI – standard MSAL mobile redirect format.
  /// Azure auto-registers msal{clientId}://auth for Mobile/Desktop platforms.
  /// No manual Azure portal configuration needed.
  static const String msRedirectUri =
      'msalc7b60d58-43f3-48cd-90a6-f74c87f1b324://auth';

  /// OAuth scopes requested from Microsoft
  static const List<String> msScopes = [
    'openid',
    'profile',
    'email',
    'User.Read',
    'offline_access',
  ];
}
