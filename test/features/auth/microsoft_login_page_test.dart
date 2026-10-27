import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/features/auth/presentation/microsoft_login_page.dart';

void main() {
  const api = 'https://api.example.test';

  test('Microsoft and API pages keep loading', () {
    expect(
      outcomeForNavigation(
        'https://login.microsoftonline.com/x/oauth2/v2.0/authorize',
        apiBaseUrl: api,
      ),
      isNull,
    );
    // The backend's own callback carries Microsoft's code; it must load.
    expect(
      outcomeForNavigation(
        '$api/auth/microsoft/callback?code=0.AAA',
        apiBaseUrl: api,
      ),
      isNull,
    );
  });

  test('the web app callback ends the page with the exchange code', () {
    final outcome = outcomeForNavigation(
      'https://web.example.test/auth/microsoft/callback?code=abc123',
      apiBaseUrl: api,
    );
    expect(outcome?.code, 'abc123');
    expect(outcome?.error, isNull);
  });

  test('login errors and inactive accounts end the page with a message', () {
    expect(
      outcomeForNavigation(
        'https://web.example.test/login?error=Akun%20tidak%20ditemukan',
        apiBaseUrl: api,
      )?.error,
      'Akun tidak ditemukan',
    );
    expect(
      outcomeForNavigation(
        'https://web.example.test/auth/inactive',
        apiBaseUrl: api,
      )?.error,
      contains('belum diaktivasi'),
    );
  });
}
