import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:neocentral/core/services/lecturer_api_service.dart';
import 'package:neocentral/core/services/student_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_test_client.dart';

/// Response shapes as sent by `services` (thesisGuidance and milestones).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LecturerApiService', () {
    test('getRequests reads every page of { requests, totalPages }', () async {
      final backend = FakeBackend((request) {
        final page = int.parse(request.url.queryParameters['page']!);
        return {
          'success': true,
          'page': page,
          'pageSize': 50,
          'total': 51,
          'totalPages': 2,
          'requests': page == 1
              ? List.generate(50, (i) => {'id': 'g$i', 'phase': 'research'})
              : [
                  {'id': 'g50', 'phase': 'proposal'},
                ],
        };
      });
      final api = LecturerApiService.withClient(backend.client);

      final items = await api.getRequests();

      expect(items.length, 51);
      expect(backend.requests.length, 2);
      expect(backend.requests.first.url.queryParameters['pageSize'], '50');
    });

    test('getPendingApproval reads { guidances, total }', () async {
      final backend = FakeBackend(
        (_) => {
          'success': true,
          'total': 1,
          'page': 1,
          'pageSize': 50,
          'guidances': [
            {'id': 'g1', 'phase': 'research'},
          ],
        },
      );
      final items = await LecturerApiService.withClient(
        backend.client,
      ).getPendingApproval();

      expect(items.single['id'], 'g1');
      expect(backend.requests.length, 1);
    });

    test('getGuidanceHistory reads { count, items }', () async {
      final backend = FakeBackend(
        (_) => {
          'success': true,
          'count': 1,
          'items': [
            {'id': 'g1', 'phase': 'proposal'},
          ],
        },
      );
      final items = await LecturerApiService.withClient(
        backend.client,
      ).getGuidanceHistory('s1');

      expect(items.single['phase'], 'proposal');
      expect(backend.requests.single.url.path,
          '/thesisGuidance/lecturer/guidance-history/s1');
    });

    test('a rejection keeps the backend reason', () async {
      final backend = FakeBackend(
        (_) => http.Response(
          jsonEncode({
            'success': false,
            'message':
                'Mahasiswa sedang cuti. Bimbingan dan milestone tidak dapat diubah selama cuti.',
          }),
          403,
        ),
      );

      await expectLater(
        LecturerApiService.withClient(backend.client).approveGuidanceRequest('g1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Mahasiswa sedang cuti'),
          ),
        ),
      );
    });
  });

  group('StudentApiService', () {
    test('getMyGuidances reads { count, items }', () async {
      final backend = FakeBackend(
        (_) => {
          'success': true,
          'count': 2,
          'items': [
            {'id': 'a', 'phase': 'proposal', 'status': 'completed'},
            {'id': 'b', 'phase': 'research', 'status': 'requested'},
          ],
        },
      );
      final items = await StudentApiService.withClient(
        backend.client,
      ).getMyGuidances();

      expect(items.map((g) => g['phase']), ['proposal', 'research']);
      expect(backend.requests.single.url.path, '/thesisGuidance/student/guidance');
    });

    test('getMilestoneList passes the phase and reads data + phase', () async {
      final backend = FakeBackend(
        (request) => {
          'success': true,
          'data': [
            {'id': 'm1', 'phase': request.url.queryParameters['phase']},
          ],
          'progress': {'total': 1},
          'phase': request.url.queryParameters['phase'] ?? 'research',
          'currentPhase': 'research',
          'readOnlyReason': 'Fase proposal sudah selesai.',
        },
      );
      final list = await StudentApiService.withClient(
        backend.client,
      ).getMilestoneList('t1', phase: 'proposal');

      expect(backend.requests.single.url.path, '/milestones/thesis/t1');
      expect(backend.requests.single.url.queryParameters, {'phase': 'proposal'});
      expect(list.milestones.single['id'], 'm1');
      expect(list.phase, 'proposal');
      expect(list.currentPhase, 'research');
      expect(list.readOnlyReason, isNotNull);
    });

    test('getMyThesisId reads thesis.id from my-thesis', () async {
      final backend = FakeBackend(
        (_) => {
          'success': true,
          'thesis': {'id': 't9', 'status': 'research'},
        },
      );

      expect(
        await StudentApiService.withClient(backend.client).getMyThesisId(),
        't9',
      );
    });
  });
}
