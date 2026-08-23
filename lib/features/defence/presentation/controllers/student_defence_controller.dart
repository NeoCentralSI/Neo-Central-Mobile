import 'package:flutter/foundation.dart';

import '../../../../core/services/defence_api_service.dart';
import '../../data/models/defence_models.dart';

class StudentDefenceController extends ChangeNotifier {
  final DefenceApiService _api;

  StudentDefenceController({DefenceApiService? api})
    : _api = api ?? DefenceApiService();

  StudentDefenceOverview? overview;
  List<DefenceHistoryItem> history = const [];
  bool isLoading = false;
  String? error;
  String? uploadingRequirementId;
  bool _disposed = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        _api.getStudentOverview(),
        _api.getStudentHistory(),
      ]);
      if (_disposed) return;
      overview = results[0] as StudentDefenceOverview;
      history = results[1] as List<DefenceHistoryItem>;
    } catch (exception) {
      if (_disposed) return;
      error = exception.toString();
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> uploadRequirement({
    required String requirementId,
    required String filePath,
    required String fileName,
  }) async {
    final current = overview;
    if (current == null || !current.canUpload) {
      throw StateError('Upload dokumen belum diizinkan oleh server.');
    }
    uploadingRequirementId = requirementId;
    error = null;
    _notify();
    try {
      await _api.uploadStudentDocument(
        current.defence?.id,
        filePath: filePath,
        fileName: fileName,
        requirementId: requirementId,
      );
      await load();
    } finally {
      if (!_disposed) {
        uploadingRequirementId = null;
        notifyListeners();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
