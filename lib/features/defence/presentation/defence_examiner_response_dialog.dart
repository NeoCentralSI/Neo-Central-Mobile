import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/defence_api_service.dart';

/// Show the "Konfirmasi Penugasan Penguji" dialog for Sidang TA.
///
/// Returns `true` if the lecturer submitted a response (Setujui / Tolak)
/// and the caller should refresh the list. Returns `null` if dismissed.
Future<bool?> showDefenceExaminerResponseDialog(
  BuildContext context, {
  required Map<String, dynamic> defence,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DefenceExaminerResponseDialog(defence: defence),
  );
}

class _DefenceExaminerResponseDialog extends StatefulWidget {
  final Map<String, dynamic> defence;
  const _DefenceExaminerResponseDialog({required this.defence});

  @override
  State<_DefenceExaminerResponseDialog> createState() =>
      _DefenceExaminerResponseDialogState();
}

class _DefenceExaminerResponseDialogState
    extends State<_DefenceExaminerResponseDialog> {
  final _api = DefenceApiService();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _submittingStatus;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _respond(String status) async {
    final defenceId = widget.defence['id']?.toString();
    final examinerId = widget.defence['myExaminerId']?.toString();
    if (defenceId == null || examinerId == null) return;

    setState(() {
      _submitting = true;
      _submittingStatus = status;
    });

    try {
      final result = await _api.respondToExaminerAssignment(
        defenceId,
        examinerId,
        status: status,
        unavailableReasons:
            status == 'unavailable' ? _reasonCtrl.text.trim() : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);

      final messenger = ScaffoldMessenger.of(context);
      final transitioned = result['defenceTransitioned'] == true;
      final msg = status == 'available'
          ? (transitioned
              ? 'Anda menyetujui penugasan. Semua penguji telah bersedia — sidang siap dijadwalkan.'
              : 'Anda telah menyetujui penugasan sebagai penguji.')
          : 'Anda telah menolak penugasan sebagai penguji.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: status == 'available'
              ? AppColors.successDark
              : AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submittingStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim respons: $e'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.defence;
    final studentName = (d['studentName'] ?? '-').toString();
    final studentNim = (d['studentNim'] ?? '-').toString();
    final thesisTitle = (d['thesisTitle'] ?? '-').toString();
    final order = d['myExaminerOrder'];
    final supervisors = (d['supervisors'] as List?) ?? const [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Konfirmasi Penugasan Penguji',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Anda ditugaskan sebagai penguji sidang tugas akhir',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconRow(
                        Icons.school_outlined,
                        bold: studentName,
                        sub: studentNim,
                      ),
                      const SizedBox(height: 10),
                      _iconRow(Icons.menu_book_outlined, sub: thesisTitle),
                      if (supervisors.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        for (final sup in _sortSupervisors(
                          supervisors
                              .whereType<Map>()
                              .map((m) => Map<String, dynamic>.from(m))
                              .toList(),
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '${(sup['role'] ?? 'Pembimbing').toString()}: '
                              '${(sup['name'] ?? '-').toString()}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Peran Anda:',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        'Penguji ${order ?? "-"}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Apakah Anda bersedia menjadi penguji untuk sidang TA '
                  'mahasiswa ini?',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 14),
                Text(
                  'Alasan Tidak Bersedia (Opsional)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonCtrl,
                  enabled: !_submitting,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Masukkan alasan jika tidak bersedia…',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _respond('unavailable'),
                        icon: _submittingStatus == 'unavailable'
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.destructive,
                                ),
                              )
                            : const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.destructive,
                          side: BorderSide(
                              color:
                                  AppColors.destructive.withValues(alpha: 0.45)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _submitting ? null : () => _respond('available'),
                        icon: _submittingStatus == 'available'
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Setujui'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, {String? bold, String? sub}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bold != null)
                Text(bold, style: AppTextStyles.label),
              if (sub != null)
                Text(
                  sub,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: bold != null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _sortSupervisors(
      List<Map<String, dynamic>> sups) {
    return sups
      ..sort((a, b) {
        final aOrder = _extractSupervisorOrder(a);
        final bOrder = _extractSupervisorOrder(b);
        return aOrder.compareTo(bOrder);
      });
  }

  int _extractSupervisorOrder(Map<String, dynamic> sup) {
    final role = (sup['role'] ?? '').toString();
    final match = RegExp(r'(\d+)').firstMatch(role);
    return int.tryParse(match?.group(1) ?? '') ?? 999;
  }
}
