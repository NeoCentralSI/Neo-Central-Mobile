import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/services/api_client.dart';

void main() {
  // ─── ApiException ─────────────────────────────────────────

  group('ApiException', () {
    test('stores statusCode and message', () {
      const ex = ApiException(404, 'Not found');
      expect(ex.statusCode, 404);
      expect(ex.message, 'Not found');
    });

    test('toString includes statusCode and message', () {
      const ex = ApiException(500, 'Server error');
      expect(ex.toString(), 'ApiException(500): Server error');
    });

    test('implements Exception', () {
      const ex = ApiException(401, 'Unauthorized');
      expect(ex, isA<Exception>());
    });
  });

  // ─── Response unwrapping patterns ─────────────────────────
  // Since _handleResponse is private and uses real HTTP,
  // we test the unwrapping patterns used across services.

  group('Response unwrapping patterns', () {
    // Simulates the unwrapping logic used in StudentApiService/LecturerApiService

    dynamic unwrapList(dynamic res, List<String> keys) {
      if (res is List) return res;
      if (res is Map) {
        for (final key in keys) {
          if (res.containsKey(key) && res[key] is List) {
            return res[key] as List;
          }
        }
      }
      return [];
    }

    test('unwraps direct List response', () {
      final result = unwrapList([1, 2, 3], ['items', 'data']);
      expect(result, [1, 2, 3]);
    });

    test('unwraps Map with "items" key', () {
      final result = unwrapList({'items': [1, 2]}, ['items', 'data']);
      expect(result, [1, 2]);
    });

    test('unwraps Map with "data" key', () {
      final result = unwrapList({'data': [3, 4]}, ['items', 'data']);
      expect(result, [3, 4]);
    });

    test('returns empty list for Map without matching key', () {
      final result = unwrapList({'other': [1]}, ['items', 'data']);
      expect(result, isEmpty);
    });

    test('returns empty list for null', () {
      final result = unwrapList(null, ['items']);
      expect(result, isEmpty);
    });

    test('returns empty list for string response', () {
      final result = unwrapList('not a list', ['items']);
      expect(result, isEmpty);
    });

    test('unwraps Map with "students" key', () {
      final result = unwrapList(
        {'students': ['s1', 's2']},
        ['students', 'data', 'items'],
      );
      expect(result, ['s1', 's2']);
    });

    test('unwraps Map with "guidances" key', () {
      final result = unwrapList(
        {'guidances': ['g1']},
        ['guidances', 'data', 'items'],
      );
      expect(result, ['g1']);
    });

    test('unwraps Map with "requests" key', () {
      final result = unwrapList(
        {'requests': ['r1', 'r2']},
        ['data', 'items', 'requests'],
      );
      expect(result, ['r1', 'r2']);
    });

    test('prefers first matching key', () {
      final result = unwrapList(
        {'items': [1], 'data': [2]},
        ['items', 'data'],
      );
      expect(result, [1]);
    });
  });

  group('Map response unwrapping', () {
    // Simulates getStudentDetail/getGuidanceDetail patterns

    Map<String, dynamic> unwrapMap(dynamic res, {String? dataKey}) {
      if (res is Map<String, dynamic>) {
        if (dataKey != null &&
            res.containsKey(dataKey) &&
            res[dataKey] is Map) {
          return res[dataKey] as Map<String, dynamic>;
        }
        return res;
      }
      return {};
    }

    test('unwraps Map with "data" envelope', () {
      final result = unwrapMap(
        {'success': true, 'data': {'id': '1', 'name': 'test'}},
        dataKey: 'data',
      );
      expect(result['id'], '1');
      expect(result['name'], 'test');
    });

    test('returns raw Map when no envelope', () {
      final result = unwrapMap(
        {'id': '1', 'name': 'test'},
        dataKey: 'data',
      );
      expect(result['id'], '1');
    });

    test('unwraps Map with "guidance" envelope', () {
      final result = unwrapMap(
        {'guidance': {'id': 'g1', 'status': 'approved'}},
        dataKey: 'guidance',
      );
      expect(result['id'], 'g1');
      expect(result['status'], 'approved');
    });

    test('returns empty map for non-Map response', () {
      expect(unwrapMap('string'), isEmpty);
      expect(unwrapMap(null), isEmpty);
      expect(unwrapMap(42), isEmpty);
    });
  });
}
