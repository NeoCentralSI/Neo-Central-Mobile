import 'package:flutter/foundation.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/yudisium_api_service.dart';
import '../../data/models/yudisium_models.dart';

class StudentYudisiumController extends ChangeNotifier {
  final YudisiumApiService _api;

  StudentYudisiumController({YudisiumApiService? api})
    : _api = api ?? YudisiumApiService();

  StudentYudisiumOverview? overview;
  StudentYudisiumRequirements? requirements;
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
        _api.getStudentYudisiumOverview(),
        _api.getStudentYudisiumRequirements(),
      ]);
      if (_disposed) return;
      overview = results[0] as StudentYudisiumOverview;
      requirements = results[1] as StudentYudisiumRequirements;
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

  Future<void> upload({
    required String filePath,
    required String fileName,
    required String requirementId,
  }) async {
    uploadingRequirementId = requirementId;
    _notify();
    try {
      await _api.uploadStudentYudisiumDocument(
        filePath: filePath,
        fileName: fileName,
        requirementId: requirementId,
      );
      if (_disposed) return;
      await load();
    } finally {
      if (!_disposed) {
        uploadingRequirementId = null;
        notifyListeners();
      }
    }
  }

  Future<ApiBinaryResponse> downloadRequirement({
    required String yudisiumId,
    required String participantId,
    required String itemId,
  }) => _api.downloadStudentRequirement(
    yudisiumId: yudisiumId,
    participantId: participantId,
    itemId: itemId,
  );

  Future<ApiBinaryResponse> downloadCplReport() =>
      _api.downloadStudentCplReport();

  Future<ApiBinaryResponse> downloadCertificate() =>
      _api.downloadStudentCertificate();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
