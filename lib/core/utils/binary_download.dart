import 'package:file_picker/file_picker.dart';

import '../services/api_client.dart';

Future<bool> saveBinaryResponse(
  ApiBinaryResponse response, {
  required String fallbackFileName,
}) async {
  final fileName = response.fileName?.trim().isNotEmpty == true
      ? response.fileName!.trim()
      : fallbackFileName;
  final extension = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : null;
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Simpan dokumen',
    fileName: fileName,
    type: extension == null ? FileType.any : FileType.custom,
    allowedExtensions: extension == null ? null : [extension],
    bytes: response.bytes,
  );
  return path != null;
}
