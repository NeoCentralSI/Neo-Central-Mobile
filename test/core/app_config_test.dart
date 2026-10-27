import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/constants/app_config.dart';

void main() {
  test('default API base URL is production', () {
    expect(AppConfig.baseUrl, 'https://api-neocentral.fathur.site');
  });

  test('default app version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(AppConfig.appVersion, match?.group(1));
  });
}
