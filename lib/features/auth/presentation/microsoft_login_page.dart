import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Outcome of the Microsoft sign-in page: an exchange code or an error.
class MicrosoftLoginOutcome {
  final String? code;
  final String? error;

  const MicrosoftLoginOutcome.code(String this.code) : error = null;
  const MicrosoftLoginOutcome.error(String this.error) : code = null;
}

/// Decides what a navigation inside the sign-in page means.
///
/// The backend's web flow ends by redirecting to the web app
/// (`<web>/auth/microsoft/callback?code=...`, `<web>/login?error=...` or
/// `<web>/auth/inactive`). Those pages are not loaded; the page closes with
/// the result instead. Navigations on the API host itself (including its own
/// `/auth/microsoft/callback`) and on Microsoft's pages continue.
MicrosoftLoginOutcome? outcomeForNavigation(
  String url, {
  required String apiBaseUrl,
}) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return null;
  final apiHost = Uri.tryParse(apiBaseUrl)?.host;
  if (uri.host == apiHost) return null;

  final path = uri.path;
  if (path.endsWith('/auth/microsoft/callback')) {
    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      return MicrosoftLoginOutcome.code(code);
    }
    return const MicrosoftLoginOutcome.error(
      'Login Microsoft gagal. Coba lagi.',
    );
  }
  if (path.endsWith('/auth/inactive')) {
    return const MicrosoftLoginOutcome.error(
      'Akun belum diaktivasi. Hubungi admin.',
    );
  }
  if (path.endsWith('/login') && uri.queryParameters.containsKey('error')) {
    final message = uri.queryParameters['error']?.trim();
    return MicrosoftLoginOutcome.error(
      message == null || message.isEmpty ? 'Login Microsoft gagal.' : message,
    );
  }
  return null;
}

/// Full-screen web page for Microsoft sign-in through the backend.
/// Pops with a [MicrosoftLoginOutcome], or null when the user closes it.
class MicrosoftLoginPage extends StatefulWidget {
  final String startUrl;
  final String apiBaseUrl;

  const MicrosoftLoginPage({
    super.key,
    required this.startUrl,
    required this.apiBaseUrl,
  });

  @override
  State<MicrosoftLoginPage> createState() => _MicrosoftLoginPageState();
}

class _MicrosoftLoginPageState extends State<MicrosoftLoginPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final outcome = outcomeForNavigation(
              request.url,
              apiBaseUrl: widget.apiBaseUrl,
            );
            if (outcome == null) return NavigationDecision.navigate;
            _finish(outcome);
            return NavigationDecision.prevent;
          },
          // Fallback for WebViews that do not report server redirects to
          // onNavigationRequest.
          onPageStarted: (url) {
            if (_check(url)) return;
            if (mounted) setState(() => _isLoading = true);
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _check(url);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            _finish(
              const MicrosoftLoginOutcome.error(
                'Tidak dapat membuka halaman login. Periksa koneksi internet.',
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.startUrl));
  }

  bool _check(String url) {
    final outcome = outcomeForNavigation(url, apiBaseUrl: widget.apiBaseUrl);
    if (outcome == null) return false;
    _finish(outcome);
    return true;
  }

  void _finish(MicrosoftLoginOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Masuk dengan Microsoft', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Tutup',
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
