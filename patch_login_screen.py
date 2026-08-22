import sys
import os

login_screen_file = r'd:\Tugas Akhir\Neo-Central-Mobile\lib\features\auth\presentation\login_screen.dart'
with open(login_screen_file, 'r', encoding='utf-8') as f:
    content = f.read()

# We need to add state variables for email and password
old_state_vars = """  bool _isLoading = false;
  String? _errorMessage;"""
new_state_vars = """  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;"""

content = content.replace(old_state_vars, new_state_vars)

# Dispose controllers
old_dispose = """  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }"""
new_dispose = """  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }"""

content = content.replace(old_dispose, new_dispose)

# Add _handleEmailLogin
handle_email_login = """
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      try {
        final fcm = FcmService();
        await fcm.init();
        await fcm.registerAfterLogin();
      } catch (_) {}

      if (!mounted) return;

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
"""

content = content.replace("  String _friendlyError", handle_email_login + "  String _friendlyError")

# Now update the UI build method
old_ui = """                          Text(
                            'Gunakan akun Microsoft Universitas Andalas Anda\\nuntuk mengakses dashboard akademik.',
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
                          if (_errorMessage != null) ...["""

new_ui = """                          Text(
                            'Gunakan email dan kata sandi Anda\\natau akun Microsoft untuk mengakses dashboard.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          
                          // --- Email / Password Form ---
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Masukkan email Anda',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email tidak boleh kosong';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Format email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleEmailLogin(),
                                  decoration: InputDecoration(
                                    labelText: 'Kata Sandi',
                                    hintText: 'Masukkan kata sandi Anda',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Kata sandi tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleEmailLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Masuk',
                                            style: AppTextStyles.label.copyWith(color: AppColors.white),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'ATAU',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                              Expanded(child: Divider(color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          
                          _MicrosoftLoginButton(
                            onPressed: _handleMicrosoftLogin,
                            isLoading: _isLoading,
                          ),
                          if (_errorMessage != null) ...["""

content = content.replace(old_ui, new_ui)

with open(login_screen_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated login_screen.dart")
