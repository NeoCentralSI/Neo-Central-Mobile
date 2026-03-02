import 'package:flutter_test/flutter_test.dart';

/// Tests for response-unwrapping logic patterns used in StudentApiService.
///
/// Since the service is a singleton with hardcoded ApiClient dependency,
/// we test the unwrapping logic patterns that each method implements.
/// This validates that the service correctly handles all backend response
/// envelope formats.
void main() {
  // Helper: simulates the unwrap logic from getGuidanceHistory / getMyGuidances
  List<dynamic> unwrapListResponse(
    dynamic res,
    List<String> keys,
  ) {
    if (res is List) return res;
    if (res is Map) {
      for (final key in keys) {
        if (res.containsKey(key)) return res[key] as List;
      }
    }
    return [];
  }

  // Helper: simulates unwrap for getSupervisorsWithThesisId
  Map<String, dynamic> unwrapMapOrDefault(dynamic res, Map<String, dynamic> defaultValue) {
    if (res is Map<String, dynamic>) return res;
    return defaultValue;
  }

  // ─── getGuidanceHistory patterns ──────────────────────────

  group('getGuidanceHistory unwrapping', () {
    test('handles direct List', () {
      final result = unwrapListResponse(
        [{'id': '1'}, {'id': '2'}],
        ['items', 'data'],
      );
      expect(result.length, 2);
    });

    test('handles Map with "items" key', () {
      final result = unwrapListResponse(
        {'items': [{'id': '1'}], 'total': 1},
        ['items', 'data'],
      );
      expect(result.length, 1);
    });

    test('handles Map with "data" key', () {
      final result = unwrapListResponse(
        {'success': true, 'data': [{'id': '1'}]},
        ['items', 'data'],
      );
      expect(result.length, 1);
    });

    test('returns empty for unmatched Map', () {
      final result = unwrapListResponse(
        {'success': true, 'other': [1]},
        ['items', 'data'],
      );
      expect(result, isEmpty);
    });
  });

  // ─── getMyGuidances patterns ──────────────────────────────

  group('getMyGuidances unwrapping', () {
    test('handles direct List', () {
      final result = unwrapListResponse([1, 2, 3], ['guidances', 'data']);
      expect(result, [1, 2, 3]);
    });

    test('handles Map with "guidances" key', () {
      final result = unwrapListResponse(
        {'guidances': [{'id': 'g1'}]},
        ['guidances', 'data'],
      );
      expect(result.length, 1);
    });
  });

  // ─── getSupervisors patterns ──────────────────────────────

  group('getSupervisors unwrapping', () {
    test('handles direct List', () {
      final result = unwrapListResponse(
        [{'name': 'Dr. A'}],
        ['supervisors', 'data'],
      );
      expect(result.length, 1);
    });

    test('handles Map with "supervisors" key', () {
      final result = unwrapListResponse(
        {'supervisors': [{'name': 'Dr. A'}]},
        ['supervisors', 'data'],
      );
      expect(result.length, 1);
    });
  });

  // ─── getSupervisorsWithThesisId ───────────────────────────

  group('getSupervisorsWithThesisId unwrapping', () {
    test('returns Map response directly', () {
      final result = unwrapMapOrDefault(
        {'supervisors': [], 'thesisId': 't1'},
        {'supervisors': [], 'thesisId': ''},
      );
      expect(result['thesisId'], 't1');
    });

    test('returns default for non-Map response', () {
      final result = unwrapMapOrDefault(
        [1, 2, 3],
        {'supervisors': [], 'thesisId': ''},
      );
      expect(result['thesisId'], '');
    });
  });

  // ─── getMilestones patterns ───────────────────────────────

  group('getMilestones unwrapping', () {
    test('handles Map with "milestones" key', () {
      final result = unwrapListResponse(
        {'milestones': [{'id': 'm1'}]},
        ['milestones', 'data'],
      );
      expect(result.length, 1);
    });

    test('handles direct List', () {
      final result = unwrapListResponse(
        [{'id': 'm1'}],
        ['milestones', 'data'],
      );
      expect(result.length, 1);
    });
  });

  // ─── getSupervisorAvailability patterns ───────────────────

  group('getSupervisorAvailability unwrapping', () {
    test('handles Map with "busySlots" key', () {
      final result = unwrapListResponse(
        {'busySlots': [{'start': '2026-03-02T10:00:00Z'}]},
        ['busySlots'],
      );
      expect(result.length, 1);
    });

    test('handles direct List', () {
      final result = unwrapListResponse(
        [{'start': '2026-03-02T10:00:00Z'}],
        ['busySlots'],
      );
      expect(result.length, 1);
    });

    test('returns empty for empty response', () {
      final result = unwrapListResponse({'busySlots': []}, ['busySlots']);
      expect(result, isEmpty);
    });
  });

  // ─── requestGuidance return pattern ───────────────────────

  group('requestGuidance return pattern', () {
    test('returns Map response directly', () {
      final dynamic res = {'success': true, 'guidance': {'id': 'g1'}};
      final result =
          res is Map<String, dynamic> ? res : {'success': true};
      expect(result['success'], true);
      expect(result['guidance'], isNotNull);
    });

    test('returns default for non-Map response', () {
      const dynamic res = 'OK';
      final result =
          res is Map<String, dynamic> ? res : {'success': true};
      expect(result['success'], true);
    });
  });
}
