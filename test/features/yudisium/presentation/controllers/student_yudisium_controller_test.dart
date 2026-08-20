import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/services/yudisium_api_service.dart';
import 'package:neocentral/features/yudisium/data/models/yudisium_models.dart';
import 'package:neocentral/features/yudisium/presentation/controllers/student_yudisium_controller.dart';

class _PendingYudisiumApiService implements YudisiumApiService {
  final overview = Completer<StudentYudisiumOverview>();
  final requirements = Completer<StudentYudisiumRequirements>();

  @override
  Future<StudentYudisiumOverview> getStudentYudisiumOverview() =>
      overview.future;

  @override
  Future<StudentYudisiumRequirements> getStudentYudisiumRequirements() =>
      requirements.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'an in-flight load completes safely after controller disposal',
    () async {
      final api = _PendingYudisiumApiService();
      final controller = StudentYudisiumController(api: api);

      final load = controller.load();
      controller.dispose();
      api.overview.completeError(StateError('late overview response'));
      api.requirements.completeError(StateError('late requirements response'));

      await expectLater(load, completes);
    },
  );
}
