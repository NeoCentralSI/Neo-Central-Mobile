import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/student_api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Screen for student to submit session summary (catatan bimbingan)
/// after a guidance session has taken place.
class SessionSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final _api = StudentApiService();
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _actionItemsController = TextEditingController();

  bool _isSubmitting = false;

  String get _guidanceId =>
      (widget.session['id'] ?? widget.session['guidanceId'] ?? '').toString();

  String get _supervisorName =>
      (widget.session['supervisorName'] ?? '-').toString();

  String get _sessionDate {
    // Prefer the raw ISO date for reliable parsing
    final isoRaw = widget.session['requestedDate'] ??
        widget.session['approvedDate'];
    if (isoRaw != null) {
      try {
        final dt = DateTime.parse(isoRaw.toString()).toLocal();
        final time =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        return '${formatDateIndonesian(dt)} • $time';
      } catch (_) {}
    }
    // Fallback: try the formatted string from backend
    final formatted = widget.session['requestedDateFormatted'] ??
        widget.session['approvedDateFormatted'];
    if (formatted != null) {
      // Backend format is "Rabu, 2026-03-04 14:00" — parse the date+time part
      final str = formatted.toString();
      final commaIdx = str.indexOf(', ');
      if (commaIdx >= 0) {
        final dayName = str.substring(0, commaIdx);
        final rest = str.substring(commaIdx + 2).trim(); // "2026-03-04 14:00"
        try {
          final parts = rest.split(' ');
          final dt = DateTime.parse(parts[0]);
          final time = parts.length > 1 ? parts[1] : '';
          return '$dayName, ${dt.day} ${_monthName(dt.month)} ${dt.year}${time.isNotEmpty ? ' • $time' : ''}';
        } catch (_) {}
      }
      return str;
    }
    return '-';
  }

  static String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _actionItemsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _api.submitSessionSummary(
        _guidanceId,
        sessionSummary: _summaryController.text.trim(),
        actionItems: _actionItemsController.text.trim().isNotEmpty
            ? _actionItemsController.text.trim()
            : null,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan bimbingan berhasil dikirim'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim catatan: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = (widget.session['studentNotes'] ??
            widget.session['topic'] ??
            'Bimbingan')
        .toString();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSecondary,
        body: Column(
          children: [
            // ── Gradient Header ──────────────────────────────
            _buildHeader(topic),

            // ── Form Content ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session info card
                      _buildSessionInfoCard(topic),
                      const SizedBox(height: AppSpacing.lg),

                      // Session summary field
                      Text(
                        'Ringkasan Sesi *',
                        style: AppTextStyles.label.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _summaryController,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: _inputDecoration(
                          hint: 'Tuliskan ringkasan pembahasan dalam sesi bimbingan ini...',
                          icon: Icons.notes_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ringkasan sesi wajib diisi';
                          }
                          if (v.trim().length < 10) {
                            return 'Ringkasan minimal 10 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Action items field
                      Text(
                        'Tindak Lanjut (Opsional)',
                        style: AppTextStyles.label.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _actionItemsController,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: _inputDecoration(
                          hint: 'Apa saja yang perlu dikerjakan setelah sesi ini...',
                          icon: Icons.checklist_rounded,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Submit button
                      AppButton(
                        label: 'Kirim Catatan',
                        icon: Icons.send_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: AppSpacing.base),
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

  Widget _buildHeader(String topic) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppColors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Catatan Bimbingan',
                    style: AppTextStyles.h2.copyWith(color: AppColors.white),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 0),
                child: Text(
                  'Isi ringkasan hasil bimbingan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(String topic) {
    return AppCard(
      child: Column(
        children: [
          InfoRow(
            icon: Icons.bookmark_outline,
            label: 'TOPIK',
            value: topic,
          ),
          const AppDivider(verticalPadding: 10),
          InfoRow(
            icon: Icons.person_outline,
            label: 'DOSEN PEMBIMBING',
            value: _supervisorName,
          ),
          const AppDivider(verticalPadding: 10),
          InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'TANGGAL SESI',
            value: _sessionDate,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12, bottom: 60),
        child: Icon(icon, size: 20, color: AppColors.textTertiary),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
      ),
    );
  }
}
