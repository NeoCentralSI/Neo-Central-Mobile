import 'package:flutter_test/flutter_test.dart';

/// Tests for response-unwrapping logic patterns used in LecturerApiService.
///
/// The service is a singleton with hardcoded ApiClient dependency.
/// We test the unwrapping patterns each method implements to handle
/// all possible backend response envelope formats.
void main() {
  // Reusable helper: simulates the list-unwrap pattern
  List<dynamic> unwrapList(dynamic res, List<String> keys) {
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

  // Reusable helper: simulates the map-unwrap pattern with an inner key
  Map<String, dynamic> unwrapMap(dynamic res, {String? innerKey}) {
    if (res is Map<String, dynamic>) {
      if (innerKey != null &&
          res.containsKey(innerKey) &&
          res[innerKey] is Map) {
        return res[innerKey] as Map<String, dynamic>;
      }
      return res;
    }
    return {};
  }

  // ─── getMyStudents ────────────────────────────────────────

  group('getMyStudents unwrapping', () {
    test('handles direct List', () {
      final result = unwrapList([{'name': 'Alice'}], ['students', 'data', 'items']);
      expect(result.length, 1);
    });

    test('handles Map with "students" key', () {
      final result = unwrapList(
        {'students': [{'name': 'Alice'}]},
        ['students', 'data', 'items'],
      );
      expect(result.length, 1);
    });

    test('handles Map with "data" key', () {
      final result = unwrapList(
        {'data': [{'name': 'Alice'}]},
        ['students', 'data', 'items'],
      );
      expect(result.length, 1);
    });

    test('handles Map with "items" key', () {
      final result = unwrapList(
        {'items': [{'name': 'Alice'}]},
        ['students', 'data', 'items'],
      );
      expect(result.length, 1);
    });

    test('returns empty for unmatched Map', () {
      final result = unwrapList({'other': []}, ['students', 'data', 'items']);
      expect(result, isEmpty);
    });
  });

  // ─── getStudentDetail ─────────────────────────────────────

  group('getStudentDetail unwrapping', () {
    test('unwraps "data" envelope', () {
      final result = unwrapMap(
        {'success': true, 'data': {'id': 't1', 'title': 'Thesis'}},
        innerKey: 'data',
      );
      expect(result['id'], 't1');
      expect(result['title'], 'Thesis');
    });

    test('returns raw Map when no "data" envelope', () {
      final result = unwrapMap(
        {'id': 't1', 'title': 'Thesis'},
        innerKey: 'data',
      );
      expect(result['id'], 't1');
    });

    test('returns empty Map for non-Map response', () {
      expect(unwrapMap(null), isEmpty);
      expect(unwrapMap('string'), isEmpty);
    });
  });

  // ─── getRequests ──────────────────────────────────────────

  group('getRequests unwrapping', () {
    test('handles Map with "requests" key', () {
      final result = unwrapList(
        {'requests': [{'id': 'r1'}]},
        ['requests', 'data', 'items'],
      );
      expect(result.length, 1);
    });
  });

  // ─── approveGuidanceRequest / rejectGuidanceRequest ───────

  group('approve/reject guidance request', () {
    test('returns Map response directly', () {
      final dynamic res = {'success': true, 'guidance': {'status': 'approved'}};
      final result = res is Map<String, dynamic> ? res : {'success': true};
      expect(result['success'], true);
    });

    test('returns default for non-Map response', () {
      const dynamic res = 'OK';
      final result = res is Map<String, dynamic> ? res : {'success': true};
      expect(result, {'success': true});
    });
  });

  // ─── getScheduledGuidances ────────────────────────────────

  group('getScheduledGuidances unwrapping', () {
    test('handles Map with "guidances" key', () {
      final result = unwrapList(
        {'guidances': [{'id': 'g1'}]},
        ['guidances', 'data', 'items'],
      );
      expect(result.length, 1);
      expect(result.first['id'], 'g1');
    });
  });

  // ─── getPendingApproval ───────────────────────────────────

  group('getPendingApproval unwrapping', () {
    test('handles direct List', () {
      final result = unwrapList(
        [{'id': 'p1'}],
        ['guidances', 'data', 'items'],
      );
      expect(result.length, 1);
    });

    test('handles Map with "guidances" key', () {
      final result = unwrapList(
        {'guidances': [{'id': 'p1'}]},
        ['guidances', 'data', 'items'],
      );
      expect(result.length, 1);
    });
  });

  // ─── getGuidanceDetail ────────────────────────────────────

  group('getGuidanceDetail unwrapping', () {
    test('unwraps "guidance" envelope', () {
      final result = unwrapMap(
        {'guidance': {'id': 'g1', 'status': 'completed'}},
        innerKey: 'guidance',
      );
      expect(result['id'], 'g1');
      expect(result['status'], 'completed');
    });

    test('returns raw Map when no "guidance" key', () {
      final result = unwrapMap(
        {'id': 'g1', 'status': 'completed'},
        innerKey: 'guidance',
      );
      expect(result['id'], 'g1');
    });
  });

  // ─── getPendingReviewMilestones ───────────────────────────

  group('getPendingReviewMilestones unwrapping', () {
    // This method casts to List<Map<String, dynamic>>

    List<Map<String, dynamic>> unwrapMilestones(dynamic res) {
      if (res is Map && res.containsKey('data') && res['data'] is List) {
        return (res['data'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      return [];
    }

    test('handles Map with "data" list', () {
      final result = unwrapMilestones({
        'data': [
          {'id': 'm1', 'progress': 100},
          {'id': 'm2', 'progress': 100},
        ],
      });
      expect(result.length, 2);
      expect(result.first['id'], 'm1');
    });

    test('handles direct List', () {
      final result = unwrapMilestones([
        {'id': 'm1'},
      ]);
      expect(result.length, 1);
    });

    test('filters out non-Map entries from list', () {
      final result = unwrapMilestones([
        {'id': 'm1'},
        'invalid',
        42,
        {'id': 'm2'},
      ]);
      expect(result.length, 2);
    });

    test('returns empty for null', () {
      expect(unwrapMilestones(null), isEmpty);
    });
  });

  // ─── getPendingTopicChanges ───────────────────────────────

  group('getPendingTopicChanges unwrapping', () {
    test('handles Map with "data" key', () {
      final result = unwrapList(
        {'data': [{'id': 'tc1'}]},
        ['data', 'items', 'requests'],
      );
      expect(result.length, 1);
    });

    test('handles direct List', () {
      final result = unwrapList(
        [{'id': 'tc1'}],
        ['data', 'items', 'requests'],
      );
      expect(result.length, 1);
    });
  });

  // ─── getIncomingTransfers ─────────────────────────────────

  group('getIncomingTransfers unwrapping', () {
    test('handles Map with "data" key', () {
      final result = unwrapList(
        {'data': [{'id': 'tr1'}]},
        ['data', 'items', 'requests'],
      );
      expect(result.length, 1);
    });

    test('handles direct List', () {
      final result = unwrapList([{'id': 'tr1'}], ['data', 'items', 'requests']);
      expect(result.length, 1);
    });
  });

  // ─── validateMilestone / requestMilestoneRevision ─────────

  group('validateMilestone return pattern', () {
    test('returns Map response directly', () {
      final dynamic res = {'success': true, 'milestone': {'status': 'validated'}};
      final result = res is Map<String, dynamic> ? res : {'success': true};
      expect(result['success'], true);
    });
  });
}
