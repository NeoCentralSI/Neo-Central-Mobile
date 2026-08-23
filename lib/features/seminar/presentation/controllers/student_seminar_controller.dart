import 'package:flutter/foundation.dart';

import '../../../../core/services/seminar_api_service.dart';
import '../../data/models/seminar_models.dart';

class StudentSeminarController extends ChangeNotifier {
  final SeminarApiService _api;

  StudentSeminarController({SeminarApiService? api})
    : _api = api ?? SeminarApiService();

  StudentSeminarOverview? overview;
  List<SeminarHistoryItem> history = const [];
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
        _api.getStudentSeminarHistory(),
      ]);
      if (_disposed) return;
      overview = results[0] as StudentSeminarOverview;
      history = results[1] as List<SeminarHistoryItem>;
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
        current.seminar?.id,
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

class SeminarAttendanceController extends ChangeNotifier {
  final SeminarApiService _api;

  SeminarAttendanceController({SeminarApiService? api})
    : _api = api ?? SeminarApiService();

  AttendanceHistory? data;
  bool isLoading = false;
  String? error;
  bool _disposed = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    _notify();
    try {
      data = await _api.getStudentAttendanceHistory();
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      _notify();
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
