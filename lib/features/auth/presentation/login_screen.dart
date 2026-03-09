import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/utils/error_mapper.dart';
import '../../shell/main_shell.dart';

/// Login screen – Microsoft SSO only. Role is determined by the backend.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _errorMessage;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleMicrosoftLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login();
      if (!mounted) return;

      // Register FCM token after successful login
      try {
        final fcm = FcmService();
        await fcm.init();
        await fcm.registerAfterLogin();
      } catch (_) {
        // Don't block login if FCM fails
      }

      if (!mounted) return;

      // Navigate to the correct shell based on role returned from backend
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              MainShell(userRole: result.user.appRole, user: result.user),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String raw) => friendlyAuthError(raw);

  @override
  Widget build(BuildContext context) {
    final topHeight = MediaQuery.of(context).size.height * 0.42;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Full-screen gradient background ──────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
              ),
            ),

            // ── White bottom card ────────────────────────────
            Positioned(
              top: topHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xxl + 8,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Masuk ke Akun Anda',
                            style: AppTextStyles.h3,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gunakan akun Microsoft Universitas Andalas Anda\nuntuk mengakses dashboard akademik.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _MicrosoftLoginButton(
                            onPressed: _handleMicrosoftLogin,
                            isLoading: _isLoading,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.destructiveLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.destructive.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.destructive,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.destructive,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'HANYA DAPAT DIAKSES OLEH CIVITAS AKADEMIKA\nUNIVERSITAS ANDALAS',
                            style: AppTextStyles.caption.copyWith(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'v1.0.0 · Universitas Andalas',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Logo section (on top of gradient) ────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: SafeArea(
                bottom: false,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppColors.transparent),
                        child: Image.asset(
                          AppAssets.logoWhite,
                          width: 72,
                          height: 72,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'NEOCENTRAL',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.white,
                          letterSpacing: 5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SISTEM INFORMASI TUGAS AKHIR',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Microsoft Login Button ───────────────────────────────────
class _MicrosoftLoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  const _MicrosoftLoginButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<_MicrosoftLoginButton> createState() => _MicrosoftLoginButtonState();
}

class _MicrosoftLoginButtonState extends State<_MicrosoftLoginButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.97 : 1.0,
          _isPressed ? 0.97 : 1.0,
          1.0,
        ),
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppAssets.microsoftLogo, width: 22, height: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Microsoft',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
