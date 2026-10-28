import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:neocentral/core/services/student_api_service.dart';
import 'package:neocentral/features/guidance/presentation/student/milestone_progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_test_client.dart';

Map<String, dynamic> _milestone(
  String id,
  String status, {
  int progress = 0,
  String? targetDate,
}) => {
  'id': id,
  'title': 'Milestone $id',
  'status': status,
  'phase': 'research',
  'progressPercentage': progress,
  'targetDate': targetDate,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  FakeBackend backendWith(
    List<Map<String, dynamic>> milestones, {
    Object? Function(http.Request request)? onWrite,
  }) => FakeBackend((request) {
    if (request.method == 'GET') {
      final phase = request.url.queryParameters['phase'];
      return {
        'success': true,
        'data': phase == 'proposal' ? <dynamic>[] : milestones,
        'phase': phase ?? 'research',
        'currentPhase': 'research',
      };
    }
    return onWrite?.call(request) ??
        {
          'success': true,
          'data': {'statusUpdated': null},
        };
  });

  Future<void> pump(WidgetTester tester, FakeBackend backend) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MilestoneProgressScreen(
          thesisId: 't1',
          api: StudentApiService.withClient(backend.client),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('not started shows Mulai and no progress slider', (tester) async {
    final backend = backendWith([
      _milestone('m1', 'not_started'),
      _milestone('m2', 'in_progress', progress: 40, targetDate: '2026-12-01'),
    ]);
    await pump(tester, backend);

    expect(find.byKey(const ValueKey('milestone-start-m1')), findsOneWidget);
    expect(find.byKey(const ValueKey('milestone-start-m2')), findsNothing);
    // Only the in-progress milestone offers "Update".
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('Mulai asks for a target date, then starts the milestone', (
    tester,
  ) async {
    final backend = backendWith([_milestone('m1', 'not_started')]);
    await pump(tester, backend);

    await tester.tap(find.byKey(const ValueKey('milestone-start-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final writes = backend.requests.where((r) => r.method == 'PATCH').toList();
    expect(writes.map((r) => r.url.path), [
      '/milestones/m1',
      '/milestones/m1/status',
    ]);
    expect(jsonDecode(writes.first.body), contains('targetDate'));
    expect(jsonDecode(writes.last.body), {'status': 'in_progress'});
    expect(find.text('Milestone berhasil dimulai'), findsOneWidget);
  });

  testWidgets('a milestone with a target date starts without asking', (
    tester,
  ) async {
    final backend = backendWith([
      _milestone('m1', 'revision_needed', targetDate: '2026-12-01'),
    ]);
    await pump(tester, backend);

    await tester.tap(find.byKey(const ValueKey('milestone-start-m1')));
    await tester.pumpAndSettle();

    final writes = backend.requests.where((r) => r.method == 'PATCH').toList();
    expect(writes.single.url.path, '/milestones/m1/status');
  });

  testWidgets('saving 100% sends progress only and reports the submission', (
    tester,
  ) async {
    final backend = backendWith(
      [_milestone('m2', 'in_progress', progress: 40, targetDate: '2026-12-01')],
      onWrite: (_) => {
        'success': true,
        'data': {'statusUpdated': 'pending_review'},
      },
    );
    await pump(tester, backend);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    final slider = find.byType(Slider);
    await tester.tapAt(tester.getTopRight(slider) + const Offset(-2, 12));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final writes = backend.requests.where((r) => r.method == 'PATCH').toList();
    expect(writes.single.url.path, '/milestones/m2/progress');
    expect(jsonDecode(writes.single.body), {'progressPercentage': 100});
    expect(
      find.text(
        'Progress 100%. Milestone diajukan ke pembimbing untuk divalidasi.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a refused start shows the backend message', (tester) async {
    final backend = backendWith(
      [_milestone('m1', 'not_started', targetDate: '2026-12-01')],
      onWrite: (_) => http.Response(
        jsonEncode({
          'success': false,
          'message':
              'Anda sedang cuti. Bimbingan dan milestone tidak dapat diubah selama cuti.',
        }),
        403,
      ),
    );
    await pump(tester, backend);

    await tester.tap(find.byKey(const ValueKey('milestone-start-m1')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Anda sedang cuti. Bimbingan dan milestone tidak dapat diubah selama cuti.',
      ),
      findsOneWidget,
    );
  });
}
