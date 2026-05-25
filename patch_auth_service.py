import sys
import os

auth_service_file = r'd:\Tugas Akhir\Neo-Central-Mobile\lib\core\services\auth_service.dart'
with open(auth_service_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Add loginWithEmail method after login() method
login_with_email_code = """
  /// Standard Email & Password Login
  Future<AuthResult> loginWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final message = body['message'] ?? 'Authentication gagal.';
        throw Exception(message);
      }

      final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
      final result = AuthResult.fromJson(tokenData);

      // Persist tokens
      await _storage.saveAuthResult(result);

      return result;
    } on http.ClientException catch (_) {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet atau IP server.',
      );
    } catch (_) {
      rethrow;
    }
  }
"""

# Find where login() ends (around line 78) and insert loginWithEmail
insertion_point = """      rethrow;
    }
  }"""

if insertion_point in content:
    content = content.replace(insertion_point, insertion_point + "\n" + login_with_email_code)
    with open(auth_service_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated auth_service.dart")
else:
    print("Failed to find insertion point in auth_service.dart")

