import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/binary_download.dart';

enum BinaryDownloadButtonStyle { outlined, text }

/// Shared stateful download action for protected seminar/defence documents.
class AuthenticatedBinaryDownloadButton extends StatefulWidget {
  final Future<ApiBinaryResponse> Function() download;
  final String fallbackFileName;
  final String successMessage;
  final String errorPrefix;
  final String label;
  final BinaryDownloadButtonStyle style;

  const AuthenticatedBinaryDownloadButton({
    super.key,
    required this.download,
    required this.fallbackFileName,
    required this.successMessage,
    required this.errorPrefix,
    required this.label,
    this.style = BinaryDownloadButtonStyle.outlined,
  });

  @override
  State<AuthenticatedBinaryDownloadButton> createState() =>
      _AuthenticatedBinaryDownloadButtonState();
}

class _AuthenticatedBinaryDownloadButtonState
    extends State<AuthenticatedBinaryDownloadButton> {
  bool _isDownloading = false;

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final response = await widget.download();
      final saved = await saveBinaryResponse(
        response,
        fallbackFileName: widget.fallbackFileName,
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.successMessage),
            backgroundColor: AppColors.successDark,
          ),
        );
      }
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.errorPrefix}: $exception'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _isDownloading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download_outlined, size: 18);
    return switch (widget.style) {
      BinaryDownloadButtonStyle.outlined => OutlinedButton.icon(
        onPressed: _isDownloading ? null : _download,
        icon: icon,
        label: Text(widget.label),
      ),
      BinaryDownloadButtonStyle.text => TextButton.icon(
        onPressed: _isDownloading ? null : _download,
        icon: icon,
        label: Text(widget.label),
      ),
    };
  }
}
