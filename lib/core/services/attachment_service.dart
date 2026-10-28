import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_config.dart';
import 'api_client.dart';

/// Result of opening an attachment, for the snackbar.
class AttachmentOpenResult {
  final bool opened;
  final String? message;

  const AttachmentOpenResult.opened() : opened = true, message = null;
  const AttachmentOpenResult.failed(String this.message) : opened = false;
}

/// Where an attachment lives.
sealed class AttachmentTarget {
  const AttachmentTarget();
}

/// A protected file on the API (`/uploads/...`), fetched with the session.
class ApiFile extends AttachmentTarget {
  /// Path on the API, percent-encoded, starting with `/`.
  final String path;
  final String fileName;
  const ApiFile(this.path, this.fileName);
}

/// A link outside the API (for example a Google Drive document link).
class ExternalLink extends AttachmentTarget {
  final Uri uri;
  const ExternalLink(this.uri);
}

/// Decides how to open [urlOrPath]: an upload path or URL on the API is
/// downloaded with the session; any other web link opens in the browser.
/// Returns null for an empty or unusable value.
AttachmentTarget? attachmentTargetFor(
  String? urlOrPath, {
  String? fileName,
  String apiBaseUrl = AppConfig.baseUrl,
}) {
  final raw = urlOrPath?.trim() ?? '';
  if (raw.isEmpty) return null;

  String path;
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final api = Uri.tryParse(apiBaseUrl);
    if (api == null || uri.host != api.host) return ExternalLink(uri);
    path = uri.path;
  } else {
    // Backend paths come as "uploads/thesis/..." or "/uploads/thesis/...";
    // a bare "thesis/..." is relative to /uploads (backend uploadUrl()).
    path = raw.startsWith('/') ? raw : '/$raw';
    if (!path.startsWith('/uploads/')) path = '/uploads$path';
  }

  // Encode each segment once (file names may contain spaces).
  final segments = path
      .split('/')
      .where((s) => s.isNotEmpty)
      .map((s) => Uri.encodeComponent(_decode(s)))
      .toList();
  if (segments.isEmpty) return null;
  final name = (fileName != null && fileName.trim().isNotEmpty)
      ? fileName.trim()
      : _decode(segments.last);
  return ApiFile('/${segments.join('/')}', name);
}

String _decode(String segment) {
  try {
    return Uri.decodeComponent(segment);
  } catch (_) {
    return segment;
  }
}

/// Opens guidance attachments.
///
/// Files under `/uploads/thesis` are protected by the backend's authGuard,
/// which reads only the Authorization header. They are therefore downloaded
/// through [ApiClient] (bearer token, refresh on 401), saved to the app's
/// temporary folder and opened with the device's default app.
class AttachmentService {
  AttachmentService({
    ApiClient? client,
    Future<Directory> Function()? tempDir,
    Future<OpenResult> Function(String path)? openFile,
    Future<bool> Function(Uri uri)? openLink,
  }) : _client = client,
       _tempDir = tempDir ?? getTemporaryDirectory,
       _openFile = openFile ?? OpenFilex.open,
       _openLink =
           openLink ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final ApiClient? _client;
  final Future<Directory> Function() _tempDir;
  final Future<OpenResult> Function(String path) _openFile;
  final Future<bool> Function(Uri uri) _openLink;

  ApiClient get _api => _client ?? ApiClient();

  Future<AttachmentOpenResult> open(
    String? urlOrPath, {
    String? fileName,
  }) async {
    final target = attachmentTargetFor(urlOrPath, fileName: fileName);
    switch (target) {
      case null:
        return const AttachmentOpenResult.failed('Dokumen tidak tersedia.');
      case ExternalLink(:final uri):
        try {
          if (await _openLink(uri)) return const AttachmentOpenResult.opened();
        } catch (_) {}
        return const AttachmentOpenResult.failed(
          'Tautan dokumen tidak dapat dibuka.',
        );
      case ApiFile(:final path, fileName: final name):
        return _download(path, name);
    }
  }

  Future<AttachmentOpenResult> _download(String path, String fileName) async {
    final ApiBinaryResponse response;
    try {
      response = await _api.getBinary(path);
    } on ApiException catch (e) {
      final message = e.message.trim();
      return AttachmentOpenResult.failed(
        message.isEmpty || message == 'Request gagal'
            ? 'Dokumen tidak dapat diunduh.'
            : message,
      );
    } catch (_) {
      return const AttachmentOpenResult.failed('Dokumen tidak dapat diunduh.');
    }

    final File file;
    try {
      final dir = Directory('${(await _tempDir()).path}/attachments');
      await dir.create(recursive: true);
      file = File('${dir.path}/${_safeName(response.fileName ?? fileName)}');
      await file.writeAsBytes(response.bytes, flush: true);
    } catch (_) {
      return const AttachmentOpenResult.failed('Dokumen tidak dapat disimpan.');
    }

    try {
      final result = await _openFile(file.path);
      return switch (result.type) {
        ResultType.done => const AttachmentOpenResult.opened(),
        ResultType.noAppToOpen => const AttachmentOpenResult.failed(
          'Tidak ada aplikasi untuk membuka dokumen ini.',
        ),
        _ => const AttachmentOpenResult.failed('Dokumen tidak dapat dibuka.'),
      };
    } catch (_) {
      return const AttachmentOpenResult.failed('Dokumen tidak dapat dibuka.');
    }
  }

  static String _safeName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .trim();
    return cleaned.isEmpty ? 'dokumen' : cleaned;
  }
}
